defmodule QuizzazWeb.HostLive.Index do
  use QuizzazWeb, :live_view

  alias Quizzaz.GameSessions.{
    RunningSessionsServer,
    GameSessionServer,
    GameSession,
    GameSessionPubSub
  }

  alias Quizzaz.Games

  def mount(
        %{"game_id" => game_id, "session_id" => session_id, "interval" => interval},
        _session,
        socket
      ) do
    {integer_interval, _} = Integer.parse(interval)
    GameSessionPubSub.subscribe_to_session(session_id)

    {:ok, game_session} =
      if RunningSessionsServer.session_exists?(session_id) do
        GameSessionServer.get_current_state(session_id)
      else
        game = Games.get_game!(game_id)

        with {:ok, session} <- GameSession.create_game_session(game, integer_interval * 1000),
             {:ok, _pid} <- GameSessionServer.start_game_session(session, session_id),
             {:ok, _state} <- GameSessionServer.start_game_wait_for_players(session_id),
             :ok <- RunningSessionsServer.put_session_name(session_id) do
          {:ok, session}
        end
      end

    {:ok,
     socket
     |> assign(:state, :waiting_for_players)
     |> assign(:game_session, game_session)
     |> assign(:session_id, session_id)
     |> assign(:question, %{})
     |> assign(:players, [])
     |> assign(:question_duration, integer_interval)
     |> assign(:countdown, integer_interval)
     |> assign(:game_id, game_id)}
  end

  def handle_event("start-game", _params, socket) do
    GameSessionPubSub.broadcast_to_session(socket.assigns.session_id, :start_game)

    case GameSessionServer.start_next_question(socket.assigns.session_id) do
      {:ok, _} ->
        countdown(socket.assigns.question_duration)

        {:noreply,
         socket
         |> assign(:state, :playing)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "This game has no players")}
    end
  end

  def handle_event("next_question", _params, socket) do
    GameSessionPubSub.broadcast_to_session(socket.assigns.session_id, :next_question)
    GameSessionServer.start_next_question(socket.assigns.session_id)
    countdown(socket.assigns.question_duration)

    {:noreply,
     socket
     |> assign(:state, :playing)}
  end

  def handle_info(:player_joined, socket) do
    {:ok, updated_session} = GameSessionServer.get_current_state(socket.assigns.session_id)
    {:noreply, socket |> assign(:game_session, updated_session)}
  end

  def handle_info({:new_question, question}, socket) do
    {:noreply, socket |> assign(:question, question)}
  end

  def handle_info(:pause_game, socket) do
    {:ok, players} = GameSessionServer.get_players(socket.assigns.session_id)

    if GameSessionServer.is_last_question?(socket.assigns.session_id) do
      GameSessionPubSub.broadcast_to_session(socket.assigns.session_id, :finished)

      {:noreply,
       socket
       |> assign(:players, players)
       |> assign(:state, :finished)}
    else
      {:noreply,
       socket
       |> assign(:players, players)
       |> assign(:countdown, socket.assigns.question_duration)
       |> assign(:state, :paused)}
    end
  end

  def handle_info({:countdown, 0}, socket) do
    {:noreply,
     socket
     |> assign(:countdown, socket.assigns.question_duration)}
  end

  def handle_info({:countdown, duration}, socket) do
    countdown(duration - 1)

    {:noreply,
     socket
     |> assign(:countdown, duration - 1)}
  end

  def handle_info(unused_message, socket) do
    IO.inspect(unused_message)
    {:noreply, socket}
  end

  defp countdown(duration) do
    Process.send_after(self(), {:countdown, duration}, 1000)
  end
end

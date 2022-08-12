defmodule QuizzazWeb.HostLive.Index do
  use QuizzazWeb, :live_view

  alias Quizzaz.GameSessions.{
    RunningSessions,
    GameSessionServer,
    GameSession,
    GameSessionPubSub
  }

  alias Quizzaz.Games

  def mount(
        %{"game_id" => game_id, "session_id" => session_id},
        _session,
        socket
      ) do
    GameSessionPubSub.subscribe_to_session(session_id)

    {:ok, game_session} =
      if RunningSessions.session_exists?(session_id) do
        GameSessionServer.get_current_state(session_id)
      else
        game = Games.get_game!(game_id)

        with {:ok, session} <-
               GameSession.create_game_session(game, 30 * 1000, session_id),
             {:ok, _pid} <- GameSessionServer.start_game_session(session, session_id),
             {:ok, _state} <- GameSessionServer.start_game_wait_for_players(session_id),
             :ok <- RunningSessions.put_session_name(session_id) do
          {:ok, session}
        end
      end

    current_question =
      if not is_nil(game_session.current_question) do
        Enum.at(game_session.questions, game_session.current_question)
      else
        %{}
      end

    {:ok,
     socket
     |> assign(:state, game_session.state)
     |> assign(:game_session, game_session)
     |> assign(:session_id, session_id)
     |> assign(:question, current_question)
     |> assign(:players, GameSession.sort_players(game_session.players))
     |> assign(:question_duration, 30)
     |> assign(:countdown, 30)
     |> assign(:game_id, game_id)}
  end

  def handle_event("select_duration", %{"select_duration" => %{"duration" => duration}}, socket) do
    {:noreply, assign(socket, :question_duration, String.to_integer(duration))}
  end

  def handle_event(
        "start-game",
        _params,
        %{assigns: %{session_id: session_id, question_duration: duration}} = socket
      ) do
    GameSessionPubSub.broadcast_to_session(session_id, :start_game)

    case GameSessionServer.start_next_question(session_id) do
      {:ok, _} ->
        GameSessionServer.start_countdown(session_id, duration)

        {:noreply,
         socket
         |> assign(:state, :playing)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "This game has no players")}
    end
  end

  def handle_event(
        "next_question",
        _params,
        %{assigns: %{session_id: session_id, question_duration: duration}} = socket
      ) do
    GameSessionPubSub.broadcast_to_session(session_id, :next_question)
    GameSessionServer.start_next_question(session_id)
    GameSessionServer.start_countdown(session_id, duration)

    {:noreply,
     socket
     |> assign(:state, :playing)}
  end

  def handle_event("pause_game", _params, %{assigns: %{session_id: session_id}} = socket) do
    Process.send(self(), :pause_game, [])
    GameSessionServer.pause_game(session_id)
    GameSessionPubSub.broadcast_to_session(session_id, :pause_game)

    {:noreply, socket}
  end

  def handle_info({:player_left, player}, socket) do
    {:ok, updated_session} = GameSessionServer.remove_player(socket.assigns.session_id, player)

    {:noreply,
     socket
     |> assign(:game_session, updated_session)
     |> assign(:players, GameSession.sort_players(updated_session.players))}
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
    sorted_players = GameSession.sort_players(players)

    if GameSessionServer.is_last_question?(socket.assigns.session_id) do
      GameSessionPubSub.broadcast_to_session(socket.assigns.session_id, :finished)

      {:noreply,
       socket
       |> assign(:players, sorted_players)
       |> assign(:state, :finished)}
    else
      {:noreply,
       socket
       |> assign(:players, players)
       |> assign(:countdown, socket.assigns.question_duration)
       |> assign(:state, :paused)}
    end
  end

  def handle_info({:countdown, duration}, socket) do
    {:noreply,
     socket
     |> assign(:countdown, duration)}
  end

  def handle_info(unused_message, socket) do
    IO.inspect(unused_message)
    {:noreply, socket}
  end
end

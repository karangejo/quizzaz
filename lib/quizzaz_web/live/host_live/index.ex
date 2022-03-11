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
    GameSessionPubSub.subscribe_to_session(session_id)

    {:ok, game_session} =
      if RunningSessionsServer.session_exists?(session_id) do
        GameSessionServer.get_current_state(session_id)
      else
        game = Games.get_game!(game_id)

        with {:ok, session} <- GameSession.create_game_session(game, interval),
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
     |> assign(:game_id, game_id)}
  end

  def handle_event("start-game", _params, socket) do
    GameSessionPubSub.broadcast_to_session(socket.assigns.session_id, :start_game)
    GameSessionServer.start_next_question(socket.assigns.session_id)
    {:noreply,
     socket
     |> assign(:state, :playing)}
  end

  def handle_info(:player_joined, socket) do
    {:ok, updated_session} = GameSessionServer.get_current_state(socket.assigns.session_id)
    {:noreply, socket |> assign(:game_session, updated_session)}
  end
end

defmodule QuizzazWeb.PlayLive.Index do
  use QuizzazWeb, :live_view

  alias QuizzazWeb.PlayLive.Schemas.JoinSession
  alias Quizzaz.GameSessions.{GameSessionPubSub, RunningSessionsServer, Player, GameSessionServer}

  def mount(_params, _session, socket) do
    changeset = JoinSession.changeset(%{})

    {:ok,
     socket
     |> assign(:state, :not_joined)
     |> assign(:session_id, nil)
     |> assign(:name, nil)
     |> assign(:question, %{})
     |> assign(:join_changeset, changeset)}
  end

  def handle_event("validate", %{"join_session" => join_session}, socket) do
    changeset =
      join_session
      |> JoinSession.changeset()
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:join_changeset, changeset)}
  end

  def handle_event(
        "join",
        %{"join_session" => %{"session_id" => session_id, "name" => name} = join_session},
        socket
      ) do
    changeset =
      join_session
      |> JoinSession.changeset()

    {:ok, name_already_exists?} = GameSessionServer.player_name_exists?(session_id, name)

    updated_socket =
      if changeset.valid? do
        if not name_already_exists? do
          if RunningSessionsServer.session_exists?(session_id) do
            GameSessionPubSub.subscribe_to_session(session_id)
            player = Player.create_new_player(name)
            GameSessionServer.player_join(session_id, player) |> IO.inspect()
            GameSessionPubSub.broadcast_to_session(session_id, :player_joined)

            socket
            |> assign(:state, :joined)
            |> assign(:session_id, session_id)
            |> assign(:name, name)
            |> assign(:join_changeset, changeset)
          else
            socket
            |> put_flash(:error, "This game does not exist")
            |> assign(:join_changeset, changeset)
          end
        else
          socket
          |> put_flash(:error, "This name already exists")
          |> assign(:join_changeset, changeset)
        end
      else
        socket
        |> put_flash(:error, "Invalid input")
        |> assign(:join_changeset, changeset |> Map.put(:action, :validate))
      end

    {:noreply, updated_socket}
  end

  def handle_event("answer_question", %{"answer" => answer}, socket) do
    GameSessionServer.answer_question(socket.assigns.session_id, socket.assigns.name, answer)
    {:noreply, socket |> assign(:state, :answered)}
  end

  def handle_info(:start_game, socket) do
    {:noreply,
     socket
     |> assign(:state, :playing)}
  end

  def handle_info({:new_question, question}, socket) do
    {:noreply, socket |> assign(:question, question)}
  end

  def handle_info(:pause_game, socket) do
    {:noreply, socket |> assign(:state, :paused)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end
end

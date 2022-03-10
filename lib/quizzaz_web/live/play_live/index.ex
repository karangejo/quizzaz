defmodule QuizzazWeb.PlayLive.Index do
  use QuizzazWeb, :live_view

  alias QuizzazWeb.PlayLive.Schemas.JoinSession
  alias Quizzaz.GameSessions.{GameSessionPubSub, RunningSessionsServer, Player, GameSessionServer}

  def mount(_params, _session, socket) do
    changeset = JoinSession.changeset(%{})
    {:ok, socket |> assign(:join_changeset, changeset)}
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
        IO.inspect(join_session)
    changeset =
      join_session
      |> JoinSession.changeset()

    updated_socket =
      if changeset.valid? do
        if RunningSessionsServer.session_exists?(session_id) do
          IO.puts("valid and exists")
          GameSessionPubSub.subscribe_to_session(session_id)
          player = Player.create_new_player(name)
          GameSessionServer.player_join(session_id, player) |> IO.inspect()
          GameSessionPubSub.broadcast_to_session(session_id, :player_joined)

          socket
          |> assign(:state, :joined)
          |> assign(:join_changeset, changeset)
        else
          IO.puts("valid not exists")

          socket
          |> put_flash(:error, "This game does not exist")
          |> assign(:join_changeset, changeset)
        end
      else
        IO.puts("not valid")

        socket
        |> put_flash(:error, "Invalid input")
        |> assign(:join_changeset, changeset |> Map.put(:action, :validate))
      end

    {:noreply, updated_socket}
  end
end

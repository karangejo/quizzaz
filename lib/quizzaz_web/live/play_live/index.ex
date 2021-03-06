defmodule QuizzazWeb.PlayLive.Index do
  use QuizzazWeb, :live_view

  alias QuizzazWeb.PlayLive.Schemas.JoinSession
  alias Quizzaz.GameSessions.{GameSessionPubSub, RunningSessionsServer, Player, GameSessionServer}
  alias Quizzaz.Games.Questions.{ScrambleLetters, ScrambleWords}

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

    updated_socket =
      if RunningSessionsServer.session_exists?(session_id) |> IO.inspect() do
        if changeset.valid? do
          {:ok, name_already_exists?} = GameSessionServer.player_name_exists?(session_id, name)

          if not name_already_exists? do
            player = Player.create_new_player(name)

            case GameSessionServer.player_join(session_id, player) do
              {:ok, _} ->
                GameSessionPubSub.subscribe_to_session(session_id)
                GameSessionPubSub.broadcast_to_session(session_id, :player_joined)

                socket
                |> assign(:state, :joined)
                |> assign(:session_id, session_id)
                |> assign(:name, name)
                |> assign(:join_changeset, changeset)

              {:error, _} ->
                socket
                |> put_flash(:error, "This game has already started")
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
      else
        socket
        |> put_flash(:error, "This game does not exist")
        |> assign(:join_changeset, changeset)
      end

    {:noreply, updated_socket}
  end

  def handle_event("answer_question", %{"open_ended_answer" => %{"answer" => answer}}, socket) do
    GameSessionServer.answer_question(socket.assigns.session_id, socket.assigns.name, answer)
    {:noreply, socket |> assign(:state, :answered)}
  end

  def handle_event("answer_question", %{"answer" => answer}, socket) do
    GameSessionServer.answer_question(socket.assigns.session_id, socket.assigns.name, answer)
    {:noreply, socket |> assign(:state, :answered)}
  end

  def handle_event("answer_scramble_letters", _params, socket) do
    GameSessionServer.answer_question(
      socket.assigns.session_id,
      socket.assigns.name,
      socket.assigns.unscrambled_word
    )

    {:noreply, socket |> assign(:state, :answered)}
  end

  def handle_event("answer_scramble_words", _params, socket) do
    GameSessionServer.answer_question(
      socket.assigns.session_id,
      socket.assigns.name,
      socket.assigns.unscrambled_words
    )

    {:noreply, socket |> assign(:state, :answered)}
  end

  def handle_event("unscrambled_word", %{"unscrambled" => unscrambled}, socket) do
    {:noreply,
     socket
     |> assign(:unscrambled_word, unscrambled)}
  end

  def handle_event("unscrambled_words", %{"unscrambled" => unscrambled}, socket) do
    {:noreply,
     socket
     |> assign(:unscrambled_words, unscrambled)}
  end

  def handle_info(:start_game, socket) do
    {:noreply,
     socket
     |> assign(:state, :playing)}
  end

  def handle_info(:next_question, socket) do
    {:noreply,
     socket
     |> assign(:state, :playing)}
  end

  def handle_info({:new_question, question}, socket) do
    case question do
      %ScrambleLetters{} = q ->
        letters = String.codepoints(q.scrambled)

        {:noreply,
         socket
         |> assign(:letters, letters)
         |> assign(:question, question)}

      %ScrambleWords{} = q ->
        {:noreply,
         socket
         |> assign(:words, q.scrambled_list)
         |> assign(:question, question)}

      _ ->
        {:noreply, socket |> assign(:question, question)}
    end
  end

  def handle_info(:pause_game, socket) do
    {:noreply, socket |> assign(:state, :paused)}
  end

  def handle_info(:finished, socket) do
    {:ok, player} = GameSessionServer.get_player(socket.assigns.session_id, socket.assigns.name)

    {:noreply,
     socket
     |> assign(:player, player)
     |> assign(:state, :finished)}
  end

  def handle_info(unused_message, socket) do
    IO.inspect(unused_message)
    {:noreply, socket}
  end
end

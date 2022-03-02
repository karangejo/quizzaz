defmodule QuizzazWeb.GameLive.FormComponent do
  use QuizzazWeb, :live_component

  alias Quizzaz.Games
  alias QuizzazWeb.GameLive.Schemas.AddQuestion
  alias Quizzaz.Games.Questions.{ScrambleLetters, ScrambleWords, MultipleChoice, OpenEnded}

  @impl true
  def update(%{game: game} = assigns, socket) do
    changeset = Games.change_game(game)
    add_question_changeset = AddQuestion.changeset(%{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:add_question_changeset, add_question_changeset)
     |> assign(:changeset, changeset)
     |> assign(:game_params, nil)
     |> assign(:question, %{})
     |> assign(:game_id, game.id)
     |> assign(:questions, [])
     |> assign(:current_question_type, nil)
     |> assign(:current_question_changeset, nil)}
  end

  def handle_event("add_question", %{"open_ended" => %{"prompt" => prompt}}, socket) do
    question = %{prompt: prompt}

    changeset =
      question
      |> OpenEnded.changeset()

    updated_socket =
      if changeset.valid? do
        socket
        |> assign(:questions, socket.assigns.questions ++ [question])
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
      else
        socket
        |> assign(
          :current_question_changeset,
          changeset
          |> Map.put(:action, :validate)
        )
      end

    {:noreply, updated_socket}
  end

  def handle_event("add_question", %{"scramble_words" => %{"answer_list" => answer_list}}, socket) do
    question =
      answer_list
      |> String.split(" ")
      |> ScrambleWords.create_params()

    changeset =
      question
      |> ScrambleWords.changeset()

    updated_socket =
      if changeset.valid? do
        socket
        |> assign(:questions, socket.assigns.questions ++ [question])
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
      else
        socket
        |> assign(
          :current_question_changeset,
          changeset
          |> Map.put(:action, :validate)
        )
      end

    {:noreply, updated_socket}
  end

  def handle_event("add_question", %{"scramble_letters" => %{"answer" => answer}}, socket) do
    question =
      answer
      |> ScrambleLetters.create_params()

    changeset =
      question
      |> ScrambleLetters.changeset()

    updated_socket =
      if changeset.valid? do
        socket
        |> assign(:questions, socket.assigns.questions ++ [question])
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
      else
        socket
        |> assign(
          :current_question_changeset,
          changeset
          |> Map.put(:action, :validate)
        )
      end

    {:noreply, updated_socket}
  end

  def handle_event(
        "add_question",
        %{
          "multiple_choice" => %{
            "prompt" => prompt,
            "answer" => answer,
            "choice_1" => c_1,
            "choice_2" => c_2,
            "choice_3" => c_3,
            "choice_4" => c_4
          }
        },
        socket
      ) do
    choices = [c_1, c_2, c_3, c_4]
    question = %{answer: answer, prompt: prompt, choices: choices}
    multiple_choice_changeset = MultipleChoice.changeset(question)

    updated_socket =
      if multiple_choice_changeset.valid? do
        socket
        |> assign(:questions, socket.assigns.questions ++ [question])
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
      else
        socket
        |> assign(
          :current_question_changeset,
          multiple_choice_changeset
          |> Map.put(:action, :validate)
        )
      end

    {:noreply, updated_socket}
  end

  def handle_event(
        "choose_question_type",
        %{"add_question" => %{"question_type" => question_type}},
        socket
      ) do
    current_question_changeset =
      case question_type do
        "multiple_choice" ->
          MultipleChoice.changeset(%{})

        "scramble_letters" ->
          ScrambleLetters.changeset(%{})

        "scramble_words" ->
          ScrambleWords.changeset(%{})

        "open_ended" ->
          OpenEnded.changeset(%{})

        _ ->
          nil
      end

    {:noreply,
     socket
     |> assign(:current_question_type, question_type)
     |> assign(:current_question_changeset, current_question_changeset)
     |> assign(:question_action, :new_question)}
  end

  @impl true
  def handle_event("validate", %{"game" => game_params}, socket) do
    changeset =
      socket.assigns.game
      |> Games.change_game(game_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:game_params, game_params)
     |> assign(:changeset, changeset)}
  end

  def handle_event("save", _params, socket) do
    game_params =
      socket.assigns.game_params
      |> Map.put("user_id", socket.assigns.user_id)

    questions = socket.assigns.questions
    save_game(socket, socket.assigns.action, game_params, questions)
  end

  defp save_game(socket, :new, game_params, questions) do
    with {:ok, game} <- Games.create_game(game_params),
         {:ok, _} <- Games.create_questions(game.id, questions) do
      {:noreply,
       socket
       |> put_flash(:info, "Game created successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # def handle_event("save", %{"game" => game_params}, socket) do
  #   save_game(socket, socket.assigns.action, game_params)
  # end

  # defp save_game(socket, :edit, game_params) do
  #   case Games.update_game(socket.assigns.game, game_params) do
  #     {:ok, _game} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Game updated successfully")
  #        |> push_redirect(to: socket.assigns.return_to)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end

  # defp save_game(socket, :new, game_params) do
  #   case Games.create_game(game_params) do
  #     {:ok, _game} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Game created successfully")
  #        |> push_redirect(to: socket.assigns.return_to)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end
end

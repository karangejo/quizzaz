defmodule QuizzazWeb.GameLive.FormComponent do
  use QuizzazWeb, :live_component

  alias Quizzaz.Games
  alias QuizzazWeb.GameLive.Schemas.AddQuestion
  alias Quizzaz.Games.Questions.{ScrambleLetters, ScrambleWords, MultipleChoice, OpenEnded}
  alias Quizzaz.Games.Question

  @impl true
  def update(%{game: game, action: live_action} = assigns, socket) do
    changeset = Games.change_game(game)
    add_question_changeset = AddQuestion.changeset(%{})

    %{questions: questions, game_params: game_params, modal_return_to: modal_return_to} =
      case live_action do
        :new ->
          %{questions: [], game_params: nil, modal_return_to: Routes.game_new_path(socket, :new)}

        :edit ->
          %{
            questions:
              game.questions
              |> Enum.map(fn %Question{content: content} -> content end),
            game_params: Map.from_struct(game),
            modal_return_to: Routes.game_edit_path(socket, :edit, game)
          }
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:add_question_changeset, add_question_changeset)
     |> assign(:changeset, changeset)
     |> assign(:game_params, game_params)
     |> assign(:question, %{})
     |> assign(:game_id, game.id)
     |> assign(:questions, questions)
     |> assign(:modal_return_to, modal_return_to)
     |> assign(:current_question_type, nil)
     |> assign(:question_action, nil)
     |> assign(:current_question_changeset, nil)}
  end

  def handle_event(
        "update_question",
        %{"open_ended" => %{"prompt" => prompt}},
        %{assigns: %{edit_question_index: index}} = socket
      ) do
    question = %{prompt: prompt}

    changeset =
      question
      |> OpenEnded.changeset()

    updated_socket =
      if changeset.valid? do
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

        socket
        |> assign(:questions, List.replace_at(socket.assigns.questions, index, question))
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
        |> assign(:question_action, nil)
        |> put_flash(:info, "Question updated")
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
        "update_question",
        %{"scramble_words" => %{"answer_list" => answer_list}},
        %{assigns: %{edit_question_index: index}} = socket
      ) do
    question = ScrambleWords.create_params(answer_list)

    changeset =
      question
      |> ScrambleWords.changeset()

    updated_socket =
      if changeset.valid? do
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

        socket
        |> assign(:questions, List.replace_at(socket.assigns.questions, index, question))
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
        |> assign(:question_action, nil)
        |> put_flash(:info, "Question updated")
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
        "update_question",
        %{"scramble_letters" => %{"answer" => answer}},
        %{assigns: %{edit_question_index: index}} = socket
      ) do
    question = ScrambleLetters.create_params(answer)

    changeset =
      question
      |> ScrambleLetters.changeset()

    updated_socket =
      if changeset.valid? do
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

        socket
        |> assign(:questions, List.replace_at(socket.assigns.questions, index, question))
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
        |> assign(:question_action, nil)
        |> put_flash(:info, "Question updated")
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
        "update_question",
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
        %{assigns: %{edit_question_index: index}} = socket
      ) do
    choices = [c_1, c_2, c_3, c_4] |> Enum.reject(fn choice -> choice == "" end)
    question = %{answer: answer, prompt: prompt, choices: choices}

    changeset =
      question
      |> MultipleChoice.changeset()

    updated_socket =
      if changeset.valid? do
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

        socket
        |> assign(:questions, List.replace_at(socket.assigns.questions, index, question))
        |> assign(:current_question_type, nil)
        |> assign(:current_question_changeset, nil)
        |> assign(:question_action, nil)
        |> put_flash(:info, "Question updated")
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

  def handle_event("add_question", %{"open_ended" => %{"prompt" => prompt}}, socket) do
    question = %{prompt: prompt}

    changeset =
      question
      |> OpenEnded.changeset()

    updated_socket =
      if changeset.valid? do
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

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
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

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
        question =
          changeset
          |> Ecto.Changeset.apply_changes()

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
    choices = [c_1, c_2, c_3, c_4] |> Enum.reject(fn choice -> choice == "" end)
    question = %{answer: answer, prompt: prompt, choices: choices}
    multiple_choice_changeset = MultipleChoice.changeset(question)

    updated_socket =
      if multiple_choice_changeset.valid? do
        question =
          multiple_choice_changeset
          |> Ecto.Changeset.apply_changes()

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
        "multiple choice" ->
          MultipleChoice.changeset(%{})

        "scramble letters" ->
          ScrambleLetters.changeset(%{})

        "scramble words" ->
          ScrambleWords.changeset(%{})

        "open ended" ->
          OpenEnded.changeset(%{})

        _ ->
          nil
      end

    type =
      case question_type do
        "" -> nil
        t -> t
      end

    {:noreply,
     socket
     |> assign(:current_question_type, type)
     |> assign(:current_question_changeset, current_question_changeset)
     |> assign(:question_action, :new_question)}
  end

  @impl true
  def handle_event("delete_question", %{"question-index" => question_index}, socket) do
    index =
      question_index
      |> String.to_integer()
      |> Kernel.-(1)

    {:noreply,
     socket
     |> assign(:questions, List.delete_at(socket.assigns.questions, index))
     |> assign(:current_question_type, nil)
     |> assign(:current_question_changeset, nil)}
  end

  @impl true
  def handle_event("edit_question", %{"question-index" => question_index}, socket) do
    index =
      question_index
      |> String.to_integer()
      |> Kernel.-(1)

    question = Enum.at(socket.assigns.questions, index)

    {question_type, changeset} =
      case question do
        %MultipleChoice{} = q ->
          {"multiple_choice",
           q
           |> MultipleChoice.add_choices()
           |> Map.from_struct()
           |> MultipleChoice.changeset()}

        %ScrambleLetters{} = q ->
          {"scramble_letters",
           q
           |> Map.from_struct()
           |> ScrambleLetters.changeset()}

        %ScrambleWords{} = q ->
          {"scramble_words",
           q
           |> ScrambleWords.answer_list_to_text()
           |> Map.from_struct()
           |> ScrambleWords.changeset()}

        %OpenEnded{} = q ->
          {"open_ended",
           q
           |> Map.from_struct()
           |> OpenEnded.changeset()}
      end

    {:noreply,
     socket
     |> assign(:current_question_type, question_type)
     |> assign(:current_question_changeset, changeset)
     |> assign(:edit_question_index, index)
     |> assign(:question_action, :edit_question)}
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

  def handle_event("save", _params, %{assigns: %{action: action}} = socket) do
    game_params =
      case action do
        :new ->
          case socket.assigns.game_params do
            nil ->
              %{}

            params ->
              params
              |> Map.put("user_id", socket.assigns.user_id)
          end

        :edit ->
          socket.assigns.game_params
      end

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

  defp save_game(socket, :edit, game_params, questions) do
    with {:ok, game} <- Games.update_game(socket.assigns.game, game_params),
         {:ok, _} <- Games.update_questions(game.id, questions) do
      {:noreply,
       socket
       |> put_flash(:info, "Game updated successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

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

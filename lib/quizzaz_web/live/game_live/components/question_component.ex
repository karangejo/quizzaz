defmodule QuizzazWeb.GameLive.QuestionComponent do
  use QuizzazWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp add_or_update_btn(action) do
    case action do
      :new_question ->
        "Add Question"

      :edit_question ->
        "Update Question"
    end
  end

  defp add_or_update_submit(action) do
    case action do
      :new_question ->
        "add_question"

      :edit_question ->
        "update_question"
    end
  end
end

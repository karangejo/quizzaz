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

  defp add_or_update_icon(action) do
    assigns = %{}

    case action do
      :new_question ->
        ~H"""
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6 text-skin-secondary"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
        """

      :edit_question ->
        ~H"""
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6 text-skin-secondary"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
          />
        </svg>
        """
    end
  end
end

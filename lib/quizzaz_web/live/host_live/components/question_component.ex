defmodule QuizzazWeb.HostLive.QuestionComponent do
  use QuizzazWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end

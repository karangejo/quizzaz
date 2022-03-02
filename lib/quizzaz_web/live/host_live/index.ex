defmodule QuizzazWeb.HostLive.Index do
  use QuizzazWeb, :live_view

  def mount(params, %{"id" => id}, socket) do
    # use id to create game genserver
    {:ok, socket}
  end
end

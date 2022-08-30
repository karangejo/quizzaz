defmodule QuizzazWeb.HostLive.DrawingsComponent do
  use QuizzazWeb, :live_component

  def update(%{players: players}, socket) do
    {:ok, assign(socket, :players, players)}
  end
end

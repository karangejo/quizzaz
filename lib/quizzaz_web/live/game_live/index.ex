defmodule QuizzazWeb.GameLive.Index do
  use QuizzazWeb, :live_view

  alias Quizzaz.Games
  alias Quizzaz.Games.Game
  alias Quizzaz.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(:user_id, user.id)
     |> assign(:games, list_games_by_user(user.id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Games")
    |> assign(:game, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    game = Games.get_game!(id)
    {:ok, _} = Games.delete_game(game)

    {:noreply, assign(socket, :games, list_games_by_user(socket.assigns.user_id))}
  end

  defp list_games_by_user(user_id) do
    Games.list_games_by_user(user_id)
  end
end

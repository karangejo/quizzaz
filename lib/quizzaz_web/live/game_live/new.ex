defmodule QuizzazWeb.GameLive.New do
  use QuizzazWeb, :live_view

  alias Quizzaz.Accounts
  alias Quizzaz.Games.Game

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(:user_id, user.id)
     |> assign(:live_action, :new)
     |> assign(:page_title, "New Game")
     |> assign(:game, %Game{})}
  end
end

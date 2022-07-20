defmodule QuizzazWeb.GameLive.Edit do
  use QuizzazWeb, :live_view

  alias Quizzaz.Accounts
  alias Quizzaz.Games

  @impl true
  def mount(%{"id" => id}, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    game = Games.get_game!(id)

    {:ok,
     socket
     |> assign(:user_id, user.id)
     |> assign(:live_action, :edit)
     |> assign(:page_title, "Edit Game")
     |> assign(:game, game)}
  end
end

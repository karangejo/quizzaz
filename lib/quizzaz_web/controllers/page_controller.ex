defmodule QuizzazWeb.PageController do
  use QuizzazWeb, :controller
  alias Quizzaz.Games

  def home(conn, _params) do
    render(conn, "home.html")
  end

  def index(conn, _params) do
    games = Games.list_public_games()
    render(conn, "public_games.html", games: games)
  end
end

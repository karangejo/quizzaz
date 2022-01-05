defmodule QuizzazWeb.PageController do
  use QuizzazWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

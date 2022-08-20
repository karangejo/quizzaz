defmodule QuizzazWeb.Themes do
  import Plug.Conn

  @theme_names ["grapes", "peaches"]

  def theme_names, do: @theme_names

  def init(default_theme), do: default_theme

  def call(%Plug.Conn{params: %{"theme" => theme}} = conn, _default_theme)
      when theme in @theme_names do
    set_theme(conn, theme)
  end

  def call(conn, default_theme) do
    set_theme(
      conn,
      conn.cookies["theme"] || default_theme
    )
  end

  defp set_theme(conn, theme) do
    conn
    |> put_resp_cookie("theme", theme, max_age: :timer.hours(24) * 365)
    |> put_session(:theme, theme)
    |> assign(:theme, theme)
  end
end

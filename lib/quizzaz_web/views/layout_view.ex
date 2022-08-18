defmodule QuizzazWeb.LayoutView do
  use QuizzazWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def active_nav?(req_path, nav_path) do
    req_path == nav_path
  end

  def get_theme(conn) do
    case conn.assigns.theme do
      "grapes" -> "theme-grapes"
      "peaches" -> "theme-peaches"
    end
  end

  defdelegate theme_names, to: QuizzazWeb.Themes
  defdelegate locale_names, to: QuizzazWeb.Locales
end

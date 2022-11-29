defmodule QuizzazWeb.Router do
  use QuizzazWeb, :router

  import QuizzazWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug QuizzazWeb.Locales, "en"
    plug QuizzazWeb.Themes, "grapes"
  end

  pipeline :site_layout, do: plug(:put_root_layout, {QuizzazWeb.LayoutView, :root})
  pipeline :game_layout, do: plug(:put_root_layout, {QuizzazWeb.LayoutView, :game})

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", QuizzazWeb do
    pipe_through [:browser, :site_layout]

    # get "/", PageController, :index
    get "/", PageController, :home
    get "/public-games", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", QuizzazWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:browser, :site_layout]

      live_dashboard "/dashboard", metrics: QuizzazWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:browser, :site_layout]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", QuizzazWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated, :site_layout]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", QuizzazWeb do
    pipe_through [:browser, :require_authenticated_user, :site_layout]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    live "/mygames", GameLive.Index, :index
    live "/mygames/new", GameLive.New, :new
    live "/mygames/:id/edit", GameLive.Edit, :edit

    live "/mygames/:id", GameLive.Show, :show
    live "/mygames/:id/show/edit", GameLive.Show, :edit
  end

  scope "/", QuizzazWeb do
    pipe_through [:browser, :site_layout]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  scope "/", QuizzazWeb do
    pipe_through [:browser, :game_layout]
    live "/host/:game_id/:session_id", HostLive.Index, :index
    live "/play", PlayLive.Index, :index
    live "/play/:name/:session_id/", PlayLive.Index, :index
  end
end

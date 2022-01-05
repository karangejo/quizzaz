defmodule Quizzaz.Repo do
  use Ecto.Repo,
    otp_app: :quizzaz,
    adapter: Ecto.Adapters.Postgres
end

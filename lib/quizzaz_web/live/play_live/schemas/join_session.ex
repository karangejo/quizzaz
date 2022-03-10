defmodule QuizzazWeb.PlayLive.Schemas.JoinSession do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :session_id, :string
    field :name, :string
  end

  def changeset(join_session \\ %__MODULE__{}, attrs) do
    join_session
    |> cast(attrs, [:session_id, :name])
    |> validate_required([:session_id, :name])
  end
end

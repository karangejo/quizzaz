defmodule Quizzaz.Games.Questions.OpenEnded do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :prompt, :string
  end

  @doc false
  def changeset(open_ended \\ %__MODULE__{}, attrs) do
    open_ended
    |> cast(attrs, [:prompt])
    |> validate_required([:prompt])
  end
end

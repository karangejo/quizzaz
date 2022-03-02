defmodule QuizzazWeb.GameLive.Schemas.AddQuestion do
  use Ecto.Schema
  import Ecto.Changeset
  alias Quizzaz.Games.Question

  embedded_schema do
    field :question_type, Ecto.Enum, values: Question.question_types()
  end

  def changeset(add_q \\ %__MODULE__{}, attrs) do
    add_q
    |> cast(attrs, [:question_type])
    |> validate_required([:question_type])
  end
end

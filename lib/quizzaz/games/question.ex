defmodule Quizzaz.Games.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :content, :map
    field :game_id, :id

    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end

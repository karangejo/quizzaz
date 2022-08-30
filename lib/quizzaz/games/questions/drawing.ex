defmodule Quizzaz.Games.Questions.Drawing do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :drawing_prompt
  end

  def changeset(drawing \\ %__MODULE__{}, attrs) do
    drawing
    |> cast(attrs, [:drawing_prompt])
    |> validate_required([:drawing_prompt])
  end
end

defmodule Quizzaz.Games.Questions.MultipleChoice do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :answer, :integer
    field :prompt, :string
    field :choices, {:array, :string}
  end

  @doc false
  def changeset(multiple_choice \\ %__MODULE__{}, attrs) do
    multiple_choice
    |> cast(attrs, [:prompt, :answer, :choices])
    |> validate_required([:prompt, :answer, :choices])
    # TODO validate answer is within range of choices
  end
end

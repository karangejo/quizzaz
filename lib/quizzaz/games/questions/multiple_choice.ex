defmodule Quizzaz.Games.Questions.MultipleChoice do
  use Ecto.Schema
  import Ecto.Changeset
  alias Quizzaz.Games.Questions.MultipleChoice

  embedded_schema do
    field :answer, :integer
    field :prompt, :string
    field :questions, {:array, :string}
  end

  @doc false
  def changeset(%MultipleChoice{} = multiple_choice, attrs) do
    multiple_choice
    |> cast(attrs, [:prompt, :answer, :questions])
    |> validate_required([:prompt, :answer, :questions])
  end
end

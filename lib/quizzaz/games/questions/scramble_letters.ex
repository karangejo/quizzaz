defmodule Quizzaz.Games.Questions.ScrambleLetters do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :answer, :string
    field :scrambled, :string
  end

  @doc false
  def changeset(sc \\ %__MODULE__{}, attrs) do
    sc
    |> cast(attrs, [:answer, :scrambled])
    |> validate_required([:answer, :scrambled])
  end

  def create_params(answer) do
    %{
      answer: answer,
      scrambled: answer |> String.graphemes() |> Enum.shuffle() |> to_string()
    }
  end
end

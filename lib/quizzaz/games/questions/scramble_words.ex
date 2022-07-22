defmodule Quizzaz.Games.Questions.ScrambleWords do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :answer_list, {:array, :string}
    field :scrambled_list, {:array, :string}
  end

  @doc false
  def changeset(sw \\ %__MODULE__{}, attrs) do
    sw
    |> cast(attrs, [:answer_list, :scrambled_list])
    |> validate_required([:answer_list, :scrambled_list])
    |> validate_length(:answer_list, min: 2)
  end

  def create_params(answer_list) when is_list(answer_list) do
    %{
      answer_list: answer_list,
      scrambled_list: Enum.shuffle(answer_list)
    }
  end
end

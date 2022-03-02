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
  end

  @spec create_params(maybe_improper_list) :: %{
          answer_list: maybe_improper_list,
          scrambled_list: list
        }
  def create_params(answer_list) when is_list(answer_list) do
    %{
      answer_list: answer_list,
      scrambled_list: Enum.shuffle(answer_list)
    }
  end
end

defmodule Quizzaz.Games.Questions.MultipleChoice do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :answer, :integer
    field :prompt, :string
    field :choices, {:array, :string}
  end

  def changeset(multiple_choice \\ %__MODULE__{}, attrs) do
    multiple_choice
    |> cast(attrs, [:prompt, :answer, :choices])
    |> validate_required([:prompt, :answer, :choices])
    |> validate_length(:choices, min: 4)
    |> validate_answer_in_choices()
  end

  defp validate_answer_in_choices(changeset) do
    choices = length(get_field(changeset, :choices))

    changeset
    |> validate_change(:answer, fn :answer, answer ->
      if answer > 0 and answer <= choices do
        []
      else
        [message: "Answer must be within the range of choices"]
      end
    end)
  end

  def add_choices(%__MODULE__{choices: choices} = mp) do
    [ch_1, ch_2, ch_3, ch_4] = choices

    mp
    |> Map.put(:choice_1, ch_1)
    |> Map.put(:choice_2, ch_2)
    |> Map.put(:choice_3, ch_3)
    |> Map.put(:choice_4, ch_4)
  end
end

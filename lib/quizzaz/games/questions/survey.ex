defmodule Quizzaz.Games.Questions.Survey do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :survey_prompt, :string
    field :choices, {:array, :string}
  end

  def changeset(survey \\ %__MODULE__{}, attrs) do
    survey
    |> cast(attrs, [:survey_prompt, :choices])
    |> validate_required([:survey_prompt, :choices])
    |> validate_length(:choices, min: 4)
  end

  def add_choices(%__MODULE__{choices: choices} = survey) do
    [ch_1, ch_2, ch_3, ch_4] = choices

    survey
    |> Map.put(:choice_1, ch_1)
    |> Map.put(:choice_2, ch_2)
    |> Map.put(:choice_3, ch_3)
    |> Map.put(:choice_4, ch_4)
  end

  def get_survey_results(players, %__MODULE__{choices: choices}) do
    results =
      players
      |> Enum.map(fn %Quizzaz.GameSessions.Player{answers: answers} ->
        answer = List.last(answers)

        if answer in choices do
          answer
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    labels = Map.keys(results)
    data = Map.values(results)
    %{"labels" => labels, "data" => data}
  end
end

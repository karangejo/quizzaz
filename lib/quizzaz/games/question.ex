defmodule Quizzaz.Games.Question do
  use Ecto.Schema
  import Ecto.Changeset
  import PolymorphicEmbed, only: [cast_polymorphic_embed: 3]

  alias Quizzaz.Games.Game
  alias Quizzaz.Games.Questions.MultipleChoice

  schema "questions" do
    belongs_to :game, Game

    field :content, PolymorphicEmbed,
      types: [
        multiple_choice: [
          module: MultipleChoice,
          identify_by_fields: [:answer, :prompt, :questions]
        ]
      ],
      on_type_not_found: :raise,
      on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:game_id])
    |> cast_polymorphic_embed(:content, required: true)
    |> validate_required([:content, :game_id])
  end
end

defmodule Quizzaz.Games.Question do
  use Ecto.Schema
  import Ecto.Changeset
  import PolymorphicEmbed, only: [cast_polymorphic_embed: 3]

  alias Quizzaz.Games.Game

  alias Quizzaz.Games.Questions.{
    Survey,
    MultipleChoice,
    OpenEnded,
    ScrambleWords,
    ScrambleLetters,
    Drawing
  }

  @question_types [
    :"multiple choice",
    :"open ended",
    :"scramble words",
    :"scramble letters",
    :survey,
    :drawing
  ]

  def question_types, do: @question_types

  schema "questions" do
    belongs_to :game, Game

    field :content, PolymorphicEmbed,
      types: [
        drawing: [
          module: Drawing,
          identify_by_fields: [:drawing_prompt]
        ],
        survey: [
          module: Survey,
          identify_by_fields: [:survey_prompt, :choices]
        ],
        multiple_choice: [
          module: MultipleChoice,
          identify_by_fields: [:answer, :prompt, :choices]
        ],
        open_ended: [
          module: OpenEnded,
          identify_by_fields: [:prompt]
        ],
        scramble_words: [
          module: ScrambleWords,
          identify_by_fields: [:answer_list, :scrambled_list]
        ],
        scramble_letters: [
          module: ScrambleLetters,
          identify_by_fields: [:answer, :scrambled]
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

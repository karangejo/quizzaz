defmodule Quizzaz.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Quizzaz.Games.Question
  alias Quizzaz.Accounts.User

  @game_types [:public, :private]

  def game_types, do: @game_types

  schema "games" do
    field :name, :string
    field :type, Ecto.Enum, values: @game_types
    belongs_to :user, User
    has_many :questions, Question

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :user_id, :type])
    |> validate_required([:name, :type, :user_id])
  end
end

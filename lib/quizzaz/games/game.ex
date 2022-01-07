defmodule Quizzaz.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Quizzaz.Games.Question
  alias Quizzaz.Accounts.User

  schema "games" do
    field :name, :string
    field :type, Ecto.Enum, values: [:public, :private]
    belongs_to :user, User
    has_many :questions, Question

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :user_id, :type])
    |> validate_required([:name, :user_id, :type])
  end
end

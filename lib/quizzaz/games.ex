defmodule Quizzaz.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Quizzaz.Repo
  alias Ecto.Multi

  alias Quizzaz.Games.Question
  alias Quizzaz.Games.Game
  alias Quizzaz.Games.Questions.{ScrambleLetters, ScrambleWords}

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  def list_public_games() do
    Question
    |> join(:left, [q], g in assoc(q, :game))
    |> where([q, g], g.type == :public)
    |> group_by([q, g], g.id)
    |> select([q, g], %{name: g.name, id: g.id, questions: count(q.id)})
    |> Repo.all()
  end

  def list_games_by_user(user_id) do
    Question
    |> join(:left, [q], g in assoc(q, :game))
    |> where([q, g], g.user_id == ^user_id)
    |> group_by([q, g], g.id)
    |> select([q, g], %{name: g.name, id: g.id, type: g.type, questions: count(q.id)})
    |> Repo.all()
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id) do
    Game
    |> where(id: ^id)
    |> preload(:questions)
    |> Repo.one!()
  end

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  # Questions

  @doc """
  Creates a question.

  ## Examples

      iex> create_question(%{field: value})
      {:ok, %Question{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_questions(game_id, questions) do
    questions
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {question, index}, acc ->
      acc
      |> Multi.insert(
        {:insert_question, index},
        %Question{}
        |> Question.changeset(%{game_id: game_id, content: Map.from_struct(question)})
      )
    end)
    |> Repo.transaction()
  end

  def update_questions(game_id, questions) do
    case delete_questions(game_id) do
      {_, nil} -> create_questions(game_id, questions)
      _ -> :error
    end
  end

  def delete_questions(game_id) do
    Question
    |> where(game_id: ^game_id)
    |> Repo.delete_all()
  end

  def create_question(attrs \\ %{}) do
    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
  end

  def create_multiple_choice_question(answer, prompt, choices, game_id)
      when is_integer(answer) and is_binary(prompt) and is_list(choices) do
    %Question{}
    |> Question.changeset(%{
      game_id: game_id,
      content: %{answer: answer, prompt: prompt, choices: choices}
    })
    |> Repo.insert()
  end

  def create_open_ended_question(prompt, game_id) when is_binary(prompt) do
    %Question{}
    |> Question.changeset(%{
      game_id: game_id,
      content: %{prompt: prompt}
    })
    |> Repo.insert()
  end

  def create_scramble_letters_question(answer, game_id) when is_binary(answer) do
    %Question{}
    |> Question.changeset(%{
      game_id: game_id,
      content: ScrambleLetters.create_params(answer)
    })
    |> Repo.insert()
  end

  def create_scramble_words_questions(answer_list, game_id) when is_list(answer_list) do
    %Question{}
    |> Question.changeset(%{
      game_id: game_id,
      content: ScrambleWords.create_params(answer_list)
    })
    |> Repo.insert()
  end

  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
  end

  def get_question!(id) do
    Question
    |> where(id: ^id)
    |> Repo.one!()
  end

  def get_game_questions(game_id) do
    Question
    |> where(game_id: ^game_id)
    |> Repo.all()
    |> Enum.map(fn %Question{content: content} -> content end)
  end
end

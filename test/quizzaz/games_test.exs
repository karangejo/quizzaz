defmodule Quizzaz.GamesTest do
  use Quizzaz.DataCase
  import Quizzaz.GamesFixtures
  import Quizzaz.AccountsFixtures

  alias Quizzaz.Repo
  alias Quizzaz.Games
  alias Quizzaz.Games.Questions.{ScrambleLetters, ScrambleWords}
  # |> Repo.preload(:questions)

  describe "games" do
    alias Quizzaz.Games.Game

    @invalid_attrs %{name: nil}

    test "list_games/0 returns all games" do
      game = game_fixture()

      assert Games.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game =
        game_fixture()
        |> Repo.preload(:questions)

      assert Games.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      %{id: user_id} = user_fixture()
      valid_attrs = %{user_id: user_id, name: "some name", type: :public}

      assert {:ok, %Game{} = game} = Games.create_game(valid_attrs)
      assert game.name == "some name"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Game{} = game} = Games.update_game(game, update_attrs)
      assert game.name == "some updated name"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture() |> Repo.preload(:questions)
      assert {:error, %Ecto.Changeset{}} = Games.update_game(game, @invalid_attrs)
      assert game == Games.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Games.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Games.change_game(game)
    end
  end

  describe "questions" do
    test "can create a mutiple_choice_question" do
      game = game_fixture()

      mutiple_choice_question = %{
        answer: 2,
        prompt: "which animal is the largest?",
        choices: ["cat", "dog", "elephant"]
      }

      assert {:ok, question} =
               Games.create_question(%{game_id: game.id, content: mutiple_choice_question})

      assert %Quizzaz.Games.Question{
               content: %Quizzaz.Games.Questions.MultipleChoice{
                 answer: 2,
                 choices: ["cat", "dog", "elephant"],
                 id: nil,
                 prompt: "which animal is the largest?"
               }
             } = question
    end

    test "can create an open ended question" do
      game = game_fixture()

      open_ended_question = %{
        prompt: "What do you think about cats?"
      }

      assert {:ok, question} =
               Games.create_question(%{game_id: game.id, content: open_ended_question})

      assert %Quizzaz.Games.Question{
               content: %Quizzaz.Games.Questions.OpenEnded{
                 prompt: "What do you think about cats?"
               }
             } = question
    end

    test "can create a scramble letters question" do
      game = game_fixture()

      scramble_letters_question = ScrambleLetters.create_params("kitten")

      assert {:ok, question} =
               Games.create_question(%{game_id: game.id, content: scramble_letters_question})

      assert %Quizzaz.Games.Question{
               content: %Quizzaz.Games.Questions.ScrambleLetters{
                 answer: "kitten"
               }
             } = question
    end

    test "can create a scramble words question" do
      game = game_fixture()

      scramble_wwords_question = ScrambleWords.create_params(~w(kittens are adorable))

      assert {:ok, question} =
               Games.create_question(%{game_id: game.id, content: scramble_wwords_question})

      assert %Quizzaz.Games.Question{
               content: %Quizzaz.Games.Questions.ScrambleWords{
                 answer_list: ["kittens", "are", "adorable"]
               }
             } = question
    end
  end
end

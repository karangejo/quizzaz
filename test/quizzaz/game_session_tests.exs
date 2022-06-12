defmodule Quizzaz.GameSessionTest do
  use Quizzaz.DataCase
  import Quizzaz.GamesFixtures

  alias Quizzaz.Games
  alias Quizzaz.GameSessions.{GameSession, Player}
  alias Quizzaz.Games.Questions.{ScrambleLetters, ScrambleWords}

  describe "multiple choice game_session" do
    setup do
      game = game_fixture()

      q_1 = %{
        answer: 2,
        prompt: "which animal is the largest?",
        choices: ["cat", "dog", "elephant"]
      }

      q_2 = %{
        answer: 0,
        prompt: "which animal is the smallest?",
        choices: ["cat", "dog", "elephant"]
      }

      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_1})
      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_2})
      {:ok, game: game}
    end

    test "can create a game session from a game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      assert %Quizzaz.GameSessions.GameSession{
               name: "some name",
               current_question: nil,
               players: [],
               question_start_time: nil,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.MultipleChoice{
                   answer: 2,
                   choices: ["cat", "dog", "elephant"],
                   id: nil,
                   prompt: "which animal is the largest?"
                 },
                 %Quizzaz.Games.Questions.MultipleChoice{
                   answer: 0,
                   choices: ["cat", "dog", "elephant"],
                   id: nil,
                   prompt: "which animal is the smallest?"
                 }
               ],
               state: :created
             } = game_session
    end

    test "can start game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      started_game =
        game_session
        |> GameSession.start_game()

      assert started_game.state == :waiting_for_players
    end

    test "can add a player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()

      assert length(updated_game.players) == 1
      assert [^player] = updated_game.players
    end

    test "can start the first question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()

      assert %GameSession{
               current_question: 0,
               name: "some name",
               players: [
                 %Quizzaz.GameSessions.Player{
                   name: "player 1",
                   score: 0
                 }
               ],
               question_start_time: _start_time,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.MultipleChoice{
                   answer: 2,
                   choices: ["cat", "dog", "elephant"],
                   id: nil,
                   prompt: "which animal is the largest?"
                 },
                 %Quizzaz.Games.Questions.MultipleChoice{
                   answer: 0,
                   choices: ["cat", "dog", "elephant"],
                   id: nil,
                   prompt: "which animal is the smallest?"
                 }
               ],
               state: :playing
             } = updated_game
    end

    test "can answer the question correctly", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "2")

      assert [%Player{name: "player 1", score: 60_000}] = updated_game.players
    end

    test "can answer the question incorrectly", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "0")

      assert [%Player{name: "player 1", score: 1000}] = updated_game.players
    end

    test "can answer the question with non existent player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player nonexistent", "2")

      assert [%Player{name: "player 1", score: 0}] = updated_game.players
    end

    test "can pause the game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "2")
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil
    end

    test "can answer 2 questions", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "2")
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "0")
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil
      assert [%Player{name: "player 1", score: 120_000}] = updated_game.players
    end

    test "can finish game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "2")
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "0")
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()

      assert updated_game.state == :finished
      assert [%Player{name: "player 1", score: 120_000}] = updated_game.players
    end
  end

  describe "open ended game_session" do
    setup do
      game = game_fixture()

      q_1 = %{
        prompt: "What do you think about cats?"
      }

      q_2 = %{
        prompt: "What do you think about dogs?"
      }

      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_1})
      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_2})
      {:ok, game: game}
    end

    test "can create a game session from a game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      assert %Quizzaz.GameSessions.GameSession{
               name: "some name",
               current_question: nil,
               players: [],
               question_start_time: nil,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.OpenEnded{
                   prompt: "What do you think about cats?"
                 },
                 %Quizzaz.Games.Questions.OpenEnded{
                   prompt: "What do you think about dogs?"
                 }
               ],
               state: :created
             } = game_session
    end

    test "can start game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      started_game =
        game_session
        |> GameSession.start_game()

      assert started_game.state == :waiting_for_players
    end

    test "can add a player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()

      assert length(updated_game.players) == 1
      assert [^player] = updated_game.players
    end

    test "can start the first question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()

      assert %GameSession{
               current_question: 0,
               name: "some name",
               players: [
                 %Quizzaz.GameSessions.Player{
                   name: "player 1",
                   score: 0
                 }
               ],
               question_start_time: _start_time,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.OpenEnded{
                   prompt: "What do you think about cats?"
                 },
                 %Quizzaz.Games.Questions.OpenEnded{
                   prompt: "What do you think about dogs?"
                 }
               ],
               state: :playing
             } = updated_game
    end

    test "can answer the question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "I think cats are the best.")

      assert [
               %Player{
                 name: "player 1",
                 score: 60_000,
                 answers: ["I think cats are the best."]
               }
             ] = updated_game.players
    end

    test "can answer the question with non existent player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player nonexistent", "I think cats are the best.")

      assert [%Player{name: "player 1", score: 0, answers: []}] = updated_game.players
    end

    test "can pause the game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "I think cats are the best.")
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil
    end

    test "can answer 2 questions", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "I think cats are the best.")
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "I don't like dogs.")
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil

      assert [
               %Player{
                 name: "player 1",
                 score: 120_000,
                 answers: ["I think cats are the best.", "I don't like dogs."]
               }
             ] = updated_game.players
    end

    test "can finish game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "I think cats are the best.")
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "I don't like dogs.")
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()

      assert updated_game.state == :finished

      assert [
               %Player{
                 name: "player 1",
                 score: 120_000,
                 answers: ["I think cats are the best.", "I don't like dogs."]
               }
             ] = updated_game.players
    end
  end

  describe "scramble_letters game_session" do
    setup do
      game = game_fixture()

      q_1 = ScrambleLetters.create_params("kitten")

      q_2 = ScrambleLetters.create_params("dog")

      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_1})
      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_2})
      {:ok, game: game}
    end

    test "can create a game session from a game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      assert %Quizzaz.GameSessions.GameSession{
               name: "some name",
               current_question: nil,
               players: [],
               question_start_time: nil,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.ScrambleLetters{
                   answer: "kitten",
                   scrambled: _q1
                 },
                 %Quizzaz.Games.Questions.ScrambleLetters{
                   answer: "dog",
                   scrambled: _q2
                 }
               ],
               state: :created
             } = game_session
    end

    test "can start game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      started_game =
        game_session
        |> GameSession.start_game()

      assert started_game.state == :waiting_for_players
    end

    test "can add a player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()

      assert length(updated_game.players) == 1
      assert [^player] = updated_game.players
    end

    test "can start the first question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()

      assert %GameSession{
               current_question: 0,
               name: "some name",
               players: [
                 %Quizzaz.GameSessions.Player{
                   name: "player 1",
                   score: 0
                 }
               ],
               question_start_time: _start_time,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.ScrambleLetters{
                   answer: "kitten",
                   scrambled: _q1
                 },
                 %Quizzaz.Games.Questions.ScrambleLetters{
                   answer: "dog",
                   scrambled: _q2
                 }
               ],
               state: :playing
             } = updated_game
    end

    test "can answer the question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "kitten")

      assert [
               %Player{
                 name: "player 1",
                 score: 60_000,
                 answers: ["kitten"]
               }
             ] = updated_game.players
    end

    test "can answer the question incorrectly", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "0")

      assert [%Player{name: "player 1", score: 1000}] = updated_game.players
    end

    test "can answer the question with non existent player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player nonexistent", "kitten")

      assert [%Player{name: "player 1", score: 0, answers: []}] = updated_game.players
    end

    test "can pause the game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "kitten")
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil
    end

    test "can answer 2 questions", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "kitten")
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "dog")
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil

      assert [
               %Player{
                 name: "player 1",
                 score: 120_000,
                 answers: ["kitten", "dog"]
               }
             ] = updated_game.players
    end

    test "can finish game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", "kitten")
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", "dog")
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()

      assert updated_game.state == :finished

      assert [
               %Player{
                 name: "player 1",
                 score: 120_000,
                 answers: ["kitten", "dog"]
               }
             ] = updated_game.players
    end
  end

  describe "scramble_words game_session" do
    setup do
      game = game_fixture()

      q_1 = ScrambleWords.create_params(~w(kittens are cute))

      q_2 = ScrambleWords.create_params(~W(dogs are friendly))

      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_1})
      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_2})
      {:ok, game: game}
    end

    test "can create a game session from a game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      assert %Quizzaz.GameSessions.GameSession{
               name: "some name",
               current_question: nil,
               players: [],
               question_start_time: nil,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.ScrambleWords{
                   answer_list: ~w(kittens are cute),
                   scrambled_list: _q1
                 },
                 %Quizzaz.Games.Questions.ScrambleWords{
                   answer_list: ~w(dogs are friendly),
                   scrambled_list: _q2
                 }
               ],
               state: :created
             } = game_session
    end

    test "can start game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      started_game =
        game_session
        |> GameSession.start_game()

      assert started_game.state == :waiting_for_players
    end

    test "can add a player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()

      assert length(updated_game.players) == 1
      assert [^player] = updated_game.players
    end

    test "can start the first question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok()

      assert %GameSession{
               current_question: 0,
               name: "some name",
               players: [
                 %Quizzaz.GameSessions.Player{
                   name: "player 1",
                   score: 0
                 }
               ],
               question_start_time: _start_time,
               question_time_interval: 30000,
               questions: [
                 %Quizzaz.Games.Questions.ScrambleWords{
                   answer_list: ~w(kittens are cute),
                   scrambled_list: _q1
                 },
                 %Quizzaz.Games.Questions.ScrambleWords{
                   answer_list: ~w(dogs are friendly),
                   scrambled_list: _q2
                 }
               ],
               state: :playing
             } = updated_game
    end

    test "can answer the question", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", ~w(kittens are cute))

      assert [
               %Player{
                 name: "player 1",
                 score: 60_000,
                 answers: [~w(kittens are cute)]
               }
             ] = updated_game.players
    end

    test "can answer the question incorrectly", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", ~w(kittens cute are))

      assert [%Player{name: "player 1", score: 1000}] = updated_game.players
    end

    test "can answer the question with non existent player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player nonexistent", ~w(kittens are cute))

      assert [%Player{name: "player 1", score: 0, answers: []}] = updated_game.players
    end

    test "can pause the game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", ~w(kittens are cute))
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil
    end

    test "can answer 2 questions", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", ~w(kittens are cute))
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", ~w(dogs are friendly))
        |> GameSession.pause_game()

      assert updated_game.state == :paused
      assert updated_game.question_start_time == nil

      assert [
               %Player{
                 name: "player 1",
                 score: 120_000,
                 answers: [~w(kittens are cute), ~w(dogs are friendly)]
               }
             ] = updated_game.players
    end

    test "can finish game", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      updated_game =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()
        |> GameSession.next_question()
        |> expect_ok
        |> GameSession.answer_question("player 1", ~w(kittens are cute))
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()
        |> GameSession.answer_question("player 1", ~w(dogs are friendly))
        |> GameSession.pause_game()
        |> GameSession.next_question()
        |> expect_ok()

      assert updated_game.state == :finished

      assert [
               %Player{
                 name: "player 1",
                 score: 120_000,
                 answers: [~w(kittens are cute), ~w(dogs are friendly)]
               }
             ] = updated_game.players
    end
  end

  describe "miscellaneous tests " do
    setup do
      game = game_fixture()

      q_1 = ScrambleWords.create_params(~w(kittens are cute))

      q_2 = ScrambleWords.create_params(~W(dogs are friendly))

      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_1})
      {:ok, _question_1} = Games.create_question(%{game_id: game.id, content: q_2})
      {:ok, game: game}
    end

    test "can remove a player", %{game: game} do
      {:ok, game_session} = GameSession.create_game_session(game, 30000, game.id)

      player = %Player{
        name: "player 1"
      }

      session =
        game_session
        |> GameSession.start_game()
        |> GameSession.add_player(player)
        |> expect_ok()

      assert [
               %Player{
                 name: "player 1",
                 score: 0,
                 answers: []
               }
             ] = session.players

      updated_session =
        session
        |> GameSession.remove_player(player)

      assert [] = updated_session.players
    end
  end

  defp expect_ok({:ok, result}) do
    result
  end
end

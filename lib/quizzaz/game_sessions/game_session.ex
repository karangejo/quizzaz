defmodule Quizzaz.GameSessions.GameSession do
  alias Quizzaz.GameSessions.Player
  alias Quizzaz.Games.Game
  alias Quizzaz.Repo
  alias Quizzaz.Games.Questions.{MultipleChoice, OpenEnded, ScrambleWords, ScrambleLetters}

  @points_per_second 2000
  @wrong_answer_points 1000

  @enforce_keys [:state, :questions]
  @type game_state :: :created | :waiting_for_players | :playing | :paused | :finished
  @type t() :: %__MODULE__{
          state: game_state,
          name: String.t(),
          session_id: String.t(),
          players: list(Player.t()),
          questions: list(Map.t()),
          current_question: Integer.t(),
          question_start_time: DateTime.t(),
          question_time_interval: Integer.t()
        }

  defstruct [
    :name,
    :session_id,
    :state,
    :players,
    :questions,
    :current_question,
    :question_start_time,
    :question_time_interval
  ]

  def create_game_session(%Game{} = game, question_interval, session_id) do
    game =
      game
      |> Repo.preload(:questions)

    {:ok,
     %__MODULE__{
       name: game.name,
       state: :created,
       session_id: session_id,
       players: [],
       questions: game.questions |> Enum.map(fn q -> q.content end),
       current_question: nil,
       question_start_time: nil,
       question_time_interval: question_interval
     }}
  end

  def start_game(%__MODULE__{state: current_state} = game_session) do
    if current_state == :created do
      %{game_session | state: :waiting_for_players}
    end
  end

  def pause_game(%__MODULE__{} = game_session) do
    %{game_session | state: :paused, question_start_time: nil}
  end

  def next_question(
        %__MODULE__{current_question: current_question, questions: questions, players: players} =
          game_session
      ) do
    if players != [] do
      num_questions = length(questions) - 1

      {:ok,
       cond do
         is_nil(current_question) ->
           %{
             game_session
             | current_question: 0,
               state: :playing,
               question_start_time: DateTime.utc_now()
           }

         num_questions > current_question ->
           %{
             game_session
             | current_question: current_question + 1,
               state: :playing,
               question_start_time: DateTime.utc_now()
           }

         num_questions <= current_question ->
           finish(game_session)
       end}
    else
      {:error, game_session}
    end
  end

  def add_player(%__MODULE__{players: players, state: state} = game_session, %Player{} = player) do
    if state == :waiting_for_players do
      {:ok, %{game_session | players: [player] ++ players}}
    else
      {:error, game_session}
    end
  end

  def remove_player(
        %__MODULE__{players: players} = game_session,
        %Player{} = player
      ) do
    %{game_session | players: Enum.reject(players, fn p -> p.name == player.name end)}
  end

  def answer_question(%__MODULE__{} = game_session, player_name, answer) do
    if game_session.state == :playing do
      if correct_answer?(answer, game_session) do
        update_correct_score(player_name, answer, game_session)
      else
        update_wrong_score(player_name, game_session)
      end
    else
      game_session
    end
  end

  def all_players_answered?(%__MODULE__{} = game_session) do
    answers_length = game_session.current_question + 1

    Enum.all?(
      game_session.players
      |> Enum.map(fn %Player{answers: answers} ->
        length(answers) == answers_length
      end)
    )
  end

  def player_name_exists?(%__MODULE__{} = game_session, player_name) do
    game_session.players |> Enum.map(fn p -> p.name end) |> Enum.member?(player_name)
  end

  def get_current_question(%__MODULE__{} = game_session) do
    Enum.at(game_session.questions, game_session.current_question)
  end

  def get_players(%__MODULE__{} = game_session) do
    game_session.players
  end

  def get_player(%__MODULE__{} = game_session, player_name) do
    game_session.players
    |> Enum.find(fn player -> player.name == player_name end)
  end

  def is_last_question?(%__MODULE__{} = game_session) do
    game_session.current_question == length(game_session.questions) - 1
  end

  defp correct_answer?(answer, %__MODULE__{} = game_session) do
    question = get_current_question(game_session)

    case question do
      %MultipleChoice{} = q ->
        q.answer == String.to_integer(answer)

      %OpenEnded{} = _q ->
        not is_nil(answer)

      %ScrambleWords{} = q ->
        q.answer_list == answer

      %ScrambleLetters{} = q ->
        q.answer == answer
    end
  end

  defp finish(%__MODULE__{} = game_session) do
    %{game_session | state: :finished}
  end

  defp update_correct_score(player_name, answer, %__MODULE__{} = game_session) do
    updated_players =
      game_session.players
      |> Enum.map(fn
        %Player{name: name, score: current_score, answers: answers} = player
        when name == player_name ->
          %Player{
            player
            | score: current_score + calculate_points(game_session),
              answers: answers ++ [answer]
          }

        %Player{} = player ->
          player
      end)

    %{game_session | players: updated_players}
  end

  defp update_wrong_score(player_name, %__MODULE__{} = game_session) do
    updated_players =
      game_session.players
      |> Enum.map(fn
        %Player{name: name, score: current_score} when name == player_name ->
          %Player{name: name, score: current_score + @wrong_answer_points}

        %Player{} = player ->
          player
      end)

    %{game_session | players: updated_players}
  end

  defp calculate_points(%__MODULE__{
         question_start_time: question_start_time,
         question_time_interval: question_time_interval
       }) do
    delay = DateTime.diff(DateTime.utc_now(), question_start_time)

    ((question_time_interval / 1000 - delay) * @points_per_second)
    |> round()
  end
end

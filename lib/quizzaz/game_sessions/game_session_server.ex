defmodule Quizzaz.GameSessions.GameSessionServer do
  use GenServer

  alias Quizzaz.GameSessions.{GameSession, GameSessionPubSub}

  # client
  def start_link({%GameSession{} = game_session, name}) do
    GenServer.start_link(__MODULE__, game_session, name: via_tuple(name))
  end

  def start_game_session(%GameSession{} = game_session, name) do
    DynamicSupervisor.start_child(
      GameSessionSupervisor,
      {__MODULE__, {game_session, name}}
    )
  end

  def answer_question(name, player_name, answer) do
    GenServer.call(via_tuple(name), {:answer_question, player_name, answer})
  end

  def start_game_wait_for_players(name) do
    GenServer.call(via_tuple(name), :start_game_wait_for_players)
  end

  def player_join(name, player) do
    GenServer.call(via_tuple(name), {:player_join, player})
  end

  def get_current_state(name) do
    GenServer.call(via_tuple(name), :get_current_state)
  end

  def start_next_question(name) do
    GenServer.call(via_tuple(name), {:start_next_question, name})
  end

  def player_name_exists?(name, player_name) do
    GenServer.call(via_tuple(name), {:player_name_exists, player_name})
  end

  defp via_tuple(name) do
    {:via, Registry, {GameSessionRegistry, name}}
  end

  # server

  def init(%GameSession{} = game_session) do
    {:ok, game_session}
  end

  def handle_call({:answer_question, player_name, answer}, _from, game_session) do
    {:reply, {:ok, game_session.state}, answer_question(game_session, player_name, answer)}
  end

  def handle_call(:start_game_wait_for_players, _from, game_session) do
    {:reply, {:ok, game_session.state}, GameSession.start_game(game_session)}
  end

  def handle_call({:player_join, player}, _from, game_session) do
    updated_session = GameSession.add_player(game_session, player)
    {:reply, {:ok, game_session.state}, updated_session}
  end

  def handle_call(:get_current_state, _from, game_session) do
    {:reply, {:ok, game_session}, game_session}
  end

  def handle_call({:start_next_question, name}, _from, game_session) do
    start_question_timer(game_session, name)
    {:reply, {:ok, game_session}, GameSession.next_question(game_session)}
  end

  def handle_call({:player_name_exists, player_name}, _from, game_session) do
    {:reply, {:ok, GameSession.player_name_exists?(game_session, player_name)}, game_session}
  end

  def handle_info({:question_finished, name}, game_session) do
    GameSessionPubSub.broadcast_to_session(name, :pause_game)
    {:noreply, GameSession.pause_game(game_session)}
  end

  defp start_question_timer(%GameSession{question_time_interval: interval}, name) do
    Process.send_after(self(), {:question_finished, name}, interval)
  end
end

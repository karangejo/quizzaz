defmodule Quizzaz.GameSessions.GameSessionServer do
  use GenServer, restart: :transient

  alias Quizzaz.GameSessions.{GameSession, GameSessionPubSub}

  # client
  def start_link({%GameSession{} = game_session, name}) do
    GenServer.start_link(__MODULE__, game_session, name: via_tuple(name))
  end

  def start_game_session(%GameSession{} = game_session, name) do
    Horde.DynamicSupervisor.start_child(
      GameSessionSupervisor,
      {__MODULE__, {game_session, name}}
    )
  end

  def terminate_game_session(name) do
    GenServer.cast(via_tuple(name), :terminate_session)
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

  def remove_player(name, player) do
    GenServer.call(via_tuple(name), {:remove_player, player})
  end

  def get_current_state(name) do
    GenServer.call(via_tuple(name), :get_current_state)
  end

  def get_players(name) do
    GenServer.call(via_tuple(name), :get_players)
  end

  def start_next_question(name) do
    GenServer.call(via_tuple(name), {:start_next_question, name})
  end

  def player_name_exists?(name, player_name) do
    GenServer.call(via_tuple(name), {:player_name_exists, player_name})
  end

  def is_last_question?(name) do
    GenServer.call(via_tuple(name), :is_last_question?)
  end

  def get_player(name, player_name) do
    GenServer.call(via_tuple(name), {:get_player, player_name})
  end

  def start_countdown(name) do
    GenServer.call(via_tuple(name), :countdown)
  end

  def pause_game(name) do
    GenServer.call(via_tuple(name), :pause_game)
  end

  def reset_game(name) do
    GenServer.call(via_tuple(name), :reset_game)
  end

  def set_question_duration(name, duration) do
    GenServer.call(via_tuple(name), {:set_question_duration, duration})
  end

  defp via_tuple(name) do
    {:via, Horde.Registry, {GameSessionRegistry, name}}
  end

  # server

  def init(%GameSession{} = game_session) do
    {:ok, game_session}
  end

  def handle_cast(:terminate_session, game_session) do
    GameSessionPubSub.broadcast_to_session(game_session.session_id, :terminate_game)
    {:stop, :shutdown, game_session}
  end

  def handle_call({:answer_question, player_name, answer}, _from, game_session) do
    updated_session = GameSession.answer_question(game_session, player_name, answer)

    if GameSession.all_players_answered?(updated_session) do
      if GameSession.is_last_question?(updated_session) do
        GameSessionPubSub.broadcast_to_session(game_session.session_id, :finished)
        finished_session = GameSession.finish_game(updated_session)
        {:reply, {:ok, finished_session.state}, finished_session}
      else
        GameSessionPubSub.broadcast_to_session(game_session.session_id, :pause_game)
        paused_session = GameSession.pause_game(updated_session)
        {:reply, {:ok, paused_session.state}, paused_session}
      end
    else
      {:reply, {:ok, updated_session.state}, updated_session}
    end
  end

  def handle_call(:start_game_wait_for_players, _from, game_session) do
    {:reply, {:ok, game_session.state}, GameSession.start_game(game_session)}
  end

  def handle_call({:player_join, player}, _from, game_session) do
    case GameSession.add_player(game_session, player) do
      {:ok, updated_session} ->
        {:reply, {:ok, game_session.state}, updated_session}

      {:error, not_updated_game_session} ->
        {:reply, {:error, game_session.state}, not_updated_game_session}
    end
  end

  def handle_call({:remove_player, player}, _from, game_session) do
    updated_game_session = GameSession.remove_player(game_session, player)
    {:reply, {:ok, updated_game_session.state}, updated_game_session}
  end

  def handle_call(:get_current_state, _from, game_session) do
    {:reply, {:ok, game_session}, game_session}
  end

  def handle_call({:start_next_question, name}, _from, game_session) do
    case GameSession.next_question(game_session) do
      {:ok, updated_game_session} ->
        GameSessionPubSub.broadcast_to_session(
          name,
          {:new_question, GameSession.get_current_question(updated_game_session)}
        )

        {:reply, {:ok, updated_game_session}, updated_game_session}

      {:error, game_session} ->
        {:reply, {:error, game_session}, game_session}
    end
  end

  def handle_call({:player_name_exists, player_name}, _from, game_session) do
    {:reply, {:ok, GameSession.player_name_exists?(game_session, player_name)}, game_session}
  end

  def handle_call(:get_players, _from, game_session) do
    {:reply, {:ok, GameSession.get_players(game_session)}, game_session}
  end

  def handle_call({:get_player, player_name}, _from, game_session) do
    {:reply, {:ok, GameSession.get_player(game_session, player_name)}, game_session}
  end

  def handle_call(:is_last_question?, _from, game_session) do
    {:reply, GameSession.is_last_question?(game_session), game_session}
  end

  def handle_call(:pause_game, _from, game_session) do
    updated_session = GameSession.pause_game(game_session)
    {:reply, {:ok, updated_session.state}, updated_session}
  end

  def handle_call(:reset_game, _from, game_session) do
    updated_session = GameSession.reset_game(game_session)
    GameSessionPubSub.broadcast_to_session(game_session.session_id, :reset_game)
    {:reply, {:ok, updated_session.state}, updated_session}
  end

  def handle_call({:set_question_duration, duration}, _from, game_session) do
    updated_session = GameSession.set_question_duration(game_session, duration)
    {:reply, {:ok, updated_session.state}, updated_session}
  end

  def handle_call(:countdown, _from, %{question_time_interval: duration} = game_session) do
    countdown(duration)
    {:reply, :ok, game_session}
  end

  def handle_info({:countdown, 0}, game_session) do
    GameSessionPubSub.broadcast_to_session(game_session.session_id, {:countdown, 0})
    Process.sleep(1000)
    GameSessionPubSub.broadcast_to_session(game_session.session_id, :pause_game)
    {:noreply, GameSession.pause_game(game_session)}
  end

  def handle_info({:countdown, duration}, %{state: state} = game_session) do
    if state in [:paused, :finished] do
      {:noreply, game_session}
    else
      GameSessionPubSub.broadcast_to_session(game_session.session_id, {:countdown, duration})
      countdown(duration - 1)
      {:noreply, game_session}
    end
  end

  defp countdown(duration) do
    Process.send_after(self(), {:countdown, duration}, 1000)
  end
end

defmodule Quizzaz.GameSessions.PlayerMonitor do
  use GenServer

  alias Quizzaz.GameSessions.GameSessionPubSub

  def start_link(%{} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def monitor(pid, name, player) do
    GenServer.call(__MODULE__, {:monitor, pid, name, player})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:monitor, pid, name, player}, _, state) do
    Process.monitor(pid)
    {:reply, :ok, Map.put(state, pid, {name, player})}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # pubsub player has left
    {session_id, player} = Map.get(state, pid)
    GameSessionPubSub.broadcast_to_session(session_id, {:player_left, player})

    {:noreply, Map.delete(state, pid)}
  end
end

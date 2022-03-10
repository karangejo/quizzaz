defmodule Quizzaz.GameSessions.RunningSessionsServer do
  use GenServer

  # client
  def start_link(state \\ MapSet.new()) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def put_session_name(name) do
    GenServer.call(__MODULE__, {:put_session_name, name})
  end

  def session_exists?(name) do
    GenServer.call(__MODULE__, {:session_exists?, name})
  end

  def remove_session_name(name) do
    GenServer.call(__MODULE__, {:remove_session_name, name})
  end

  # server

  def init(state) do
    {:ok, state}
  end

  def handle_call({:put_session_name, name}, _from, state) do
    updated_state = MapSet.put(state, name)
    {:reply, :ok, updated_state}
  end

  def handle_call({:remove_session_name, name}, _from, state) do
    updated_state = MapSet.delete(state, name)
    {:reply, :ok, updated_state}
  end

  def handle_call({:session_exists?, name}, _from, state) do
    {:reply, MapSet.member?(state, name), state}
  end
end

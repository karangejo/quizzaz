defmodule Quizzaz.GameSessions.RunningSessions do
  alias :mnesia, as: Mnesia

  def put_session_name(name) do
    fn -> Mnesia.write({GameSessions, name, name}) end
    |> Mnesia.transaction()
    |> case do
      {:atomic, _} -> :ok
      {:aborted, _} -> :error
    end
  end

  def remove_session_name(name) do
    fn -> Mnesia.delete({GameSessions, name}) end
    |> Mnesia.transaction()
    |> case do
      {:atomic, _} -> :ok
      {:aborted, _} -> :error
    end
  end

  def session_exists?(name) do
    fn -> Mnesia.read({GameSessions, name}) end
    |> Mnesia.transaction()
    |> case do
      {:atomic, []} -> false
      _ -> true
    end
  end

  def list_sessions() do
    fn -> Mnesia.all_keys(GameSessions) end
    |> Mnesia.transaction()
    |> case do
      {:atomic, sessions} -> sessions
      _ -> []
    end
  end
end

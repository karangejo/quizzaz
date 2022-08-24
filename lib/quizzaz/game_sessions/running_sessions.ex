defmodule Quizzaz.GameSessions.RunningSessions do
  alias Horde.Registry

  def list_sessions() do
    match_pattern = {:"$1", :_, :_}
    guards = []
    body = [:"$1"]
    Registry.select(GameSessionRegistry, [{match_pattern, guards, body}])
  end

  def session_exists?(name) do
    case Registry.lookup(GameSessionRegistry, name) do
      [] -> false
      _ -> true
    end
  end
end

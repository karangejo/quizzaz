defmodule Quizzaz.GameSessions.GameSessionPubSub do
  alias Phoenix.PubSub

  def subscribe_to_session(session_id) do
    PubSub.subscribe(Quizzaz.PubSub, session_id)
  end

  def broadcast_to_session(session_id, payload) do
    PubSub.broadcast(Quizzaz.PubSub, session_id, payload)
  end
end

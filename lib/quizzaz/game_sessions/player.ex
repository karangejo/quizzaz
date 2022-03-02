defmodule Quizzaz.GameSessions.Player do
  @enforce_keys [:name]
  @type t() :: %__MODULE__{
          name: String.t(),
          score: Integer.t(),
          answers: list(any())
        }
  defstruct [
    :name,
    score: 0,
    answers: []
  ]
end

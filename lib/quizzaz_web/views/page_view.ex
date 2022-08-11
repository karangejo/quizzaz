defmodule QuizzazWeb.PageView do
  use QuizzazWeb, :view

  def gen_rand_id() do
    Ecto.UUID.generate()
    |> String.replace("-", "")
    |> String.slice(0..12)
  end
end

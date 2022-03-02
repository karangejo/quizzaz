defmodule Quizzaz.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Quizzaz.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :public
      })
      |> Quizzaz.Games.create_game()

    game
  end
end

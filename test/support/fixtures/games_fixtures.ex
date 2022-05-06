defmodule Quizzaz.GamesFixtures do
  import Quizzaz.AccountsFixtures

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Quizzaz.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    %{id: user_id} = user_fixture()

    {:ok, game} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :public,
        user_id: user_id
      })
      |> Quizzaz.Games.create_game()

    game
  end
end

defmodule Quizzaz.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :content, :jsonb
      add :game_id, references(:games, on_delete: :delete_all)

      timestamps()
    end

    create index(:questions, [:game_id])
  end
end

defmodule Chess.Repo.Migrations.CreateMoves do
  use Ecto.Migration

  def change do
    create table(:moves, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :from_column, :integer, null: false
      add :from_row, :integer, null: false
      add :to_column, :integer, null: false
      add :to_row, :integer, null: false
      add :game_id, references("games")

      timestamps(type: :utc_datetime)
    end
  end
end

defmodule Chess.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :who, :text
      add :body, :text
      add :game_id, references(:games, on_delete: :nothing, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:game_id])
  end
end

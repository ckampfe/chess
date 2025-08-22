defmodule Chess.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :who, :string
    field :body, :string
    field :game_id, Ecto.UUID

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:who, :body])
    |> validate_required([:who, :body])
  end
end

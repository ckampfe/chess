defmodule Chess.Move do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "moves" do
    field :from_column, :integer
    field :from_row, :integer
    field :to_column, :integer
    field :to_row, :integer

    belongs_to :game, Chess.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(move, attrs) do
    move
    |> cast(attrs, [:from_column, :from_row, :to_column, :to_row])
    |> validate_required([:from_column, :from_row, :to_column, :to_row])
  end
end

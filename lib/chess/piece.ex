defmodule Chess.Piece do
  defstruct [:color, :kind, :column, :row]

  def naive_potential_moves(piece) do
    case piece.kind do
      :king ->
        [
          {piece.column + 1, piece.row + 1},
          {piece.column + 1, piece.row - 1},
          {piece.column + 1, piece.row},
          {piece.column - 1, piece.row + 1},
          {piece.column - 1, piece.row - 1},
          {piece.column - 1, piece.row},
          {piece.column, piece.row + 1},
          {piece.column, piece.row - 1}
        ]
        |> Enum.filter(fn {column, row} ->
          column >= 0 && column <= 7 && row >= 0 && row <= 7
        end)
        |> MapSet.new()

      :queen ->
        MapSet.union(rook_moves(piece), bishop_moves(piece))

      :rook ->
        rook_moves(piece)

      :bishop ->
        bishop_moves(piece)

      :knight ->
        [
          {piece.column + 2, piece.row + 1},
          {piece.column + 2, piece.row - 1},
          {piece.column + 1, piece.row + 2},
          {piece.column + 1, piece.row - 2},
          {piece.column - 2, piece.row + 1},
          {piece.column - 2, piece.row - 1},
          {piece.column - 1, piece.row + 2},
          {piece.column - 1, piece.row - 2}
        ]
        |> Enum.filter(fn {column, row} ->
          column <= 7 && row <= 7 && column >= 0 && row >= 0
        end)
        |> MapSet.new()

      :pawn ->
        case piece.color do
          :white ->
            [
              {piece.column + 1, piece.row + 1},
              {piece.column - 1, piece.row + 1},
              {piece.column, piece.row + 1}
            ]
            |> Enum.filter(fn {column, row} ->
              column <= 7 && row <= 7 && column >= 0 && row >= 0
            end)
            |> MapSet.new()

          :black ->
            [
              {piece.column + 1, piece.row - 1},
              {piece.column - 1, piece.row - 1},
              {piece.column, piece.row - 1}
            ]
            |> Enum.filter(fn {column, row} ->
              column <= 7 && row <= 7 && column >= 0 && row >= 0
            end)
            |> MapSet.new()
        end
    end
  end

  defp rook_moves(piece) do
    0..7
    |> Enum.flat_map(fn mod ->
      [
        {piece.column + mod, piece.row},
        {piece.column - mod, piece.row},
        {piece.column, piece.row + mod},
        {piece.column, piece.row - mod}
      ]
    end)
    |> Enum.filter(fn {column, row} ->
      column in 0..7 && row in 0..7
    end)
    |> MapSet.new()
  end

  defp bishop_moves(piece) do
    0..7
    |> Enum.flat_map(fn mod ->
      [
        {piece.column + mod, piece.row + mod},
        {piece.column - mod, piece.row + mod},
        {piece.column + mod, piece.row - mod},
        {piece.column - mod, piece.row - mod}
      ]
    end)
    |> Enum.filter(fn {column, row} ->
      column in 0..7 && row in 0..7
    end)
    |> MapSet.new()
  end

  def repr(nil), do: ""

  def repr(piece) do
    case piece.color do
      :black ->
        case piece.kind do
          :king ->
            "♚"

          :queen ->
            "♛"

          :rook ->
            "♜"

          :bishop ->
            "♝"

          :knight ->
            "♞"

          :pawn ->
            "♟"
        end

      :white ->
        case piece.kind do
          :king ->
            "♔"

          :queen ->
            "♕"

          :rook ->
            "♖"

          :bishop ->
            "♗"

          :knight ->
            "♘"

          :pawn ->
            "♙"
        end
    end
  end
end

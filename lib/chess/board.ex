defmodule Chess.Board do
  alias Chess.Piece

  def new do
    [
      # white pieces
      %Piece{color: :white, kind: :rook, column: 0, row: 0},
      %Piece{color: :white, kind: :knight, column: 1, row: 0},
      %Piece{color: :white, kind: :bishop, column: 2, row: 0},
      %Piece{color: :white, kind: :queen, column: 3, row: 0},
      %Piece{color: :white, kind: :king, column: 4, row: 0},
      %Piece{color: :white, kind: :bishop, column: 5, row: 0},
      %Piece{color: :white, kind: :knight, column: 6, row: 0},
      %Piece{color: :white, kind: :rook, column: 7, row: 0},
      # white pawns
      %Piece{color: :white, kind: :pawn, column: 0, row: 1},
      %Piece{color: :white, kind: :pawn, column: 1, row: 1},
      %Piece{color: :white, kind: :pawn, column: 2, row: 1},
      %Piece{color: :white, kind: :pawn, column: 3, row: 1},
      %Piece{color: :white, kind: :pawn, column: 4, row: 1},
      %Piece{color: :white, kind: :pawn, column: 5, row: 1},
      %Piece{color: :white, kind: :pawn, column: 6, row: 1},
      %Piece{color: :white, kind: :pawn, column: 7, row: 1},
      # black pieces
      %Piece{color: :black, kind: :rook, column: 0, row: 7},
      %Piece{color: :black, kind: :knight, column: 1, row: 7},
      %Piece{color: :black, kind: :bishop, column: 2, row: 7},
      %Piece{color: :black, kind: :queen, column: 3, row: 7},
      %Piece{color: :black, kind: :king, column: 4, row: 7},
      %Piece{color: :black, kind: :bishop, column: 5, row: 7},
      %Piece{color: :black, kind: :knight, column: 6, row: 7},
      %Piece{color: :black, kind: :rook, column: 7, row: 7},
      # black pawns
      %Piece{color: :black, kind: :pawn, column: 0, row: 6},
      %Piece{color: :black, kind: :pawn, column: 1, row: 6},
      %Piece{color: :black, kind: :pawn, column: 2, row: 6},
      %Piece{color: :black, kind: :pawn, column: 3, row: 6},
      %Piece{color: :black, kind: :pawn, column: 4, row: 6},
      %Piece{color: :black, kind: :pawn, column: 5, row: 6},
      %Piece{color: :black, kind: :pawn, column: 6, row: 6},
      %Piece{color: :black, kind: :pawn, column: 7, row: 6}
    ]
  end

  def get(board, {column, row}) do
    Enum.find(board, fn piece ->
      piece.column == column && piece.row == row
    end)
  end

  def moves_for_piece(board, position) do
    case get(board, position) do
      nil ->
        MapSet.new(0)

      piece ->
        Piece.naive_potential_moves(piece)
    end
  end
end

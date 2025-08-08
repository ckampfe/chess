defmodule Chess.Board do
  alias Chess.Pieces.{King, Queen, Rook, Bishop, Knight, Pawn}
  alias Chess.Piece

  def new do
    [
      Rook.new(:white, 0, 0),
      Knight.new(:white, 1, 0),
      Bishop.new(:white, 2, 0),
      Queen.new(:white, 3, 0),
      King.new(:white, 4, 0),
      Bishop.new(:white, 5, 0),
      Knight.new(:white, 6, 0),
      Rook.new(:white, 7, 0),
      #
      Pawn.new(:white, 0, 1),
      Pawn.new(:white, 1, 1),
      Pawn.new(:white, 2, 1),
      Pawn.new(:white, 3, 1),
      Pawn.new(:white, 4, 1),
      Pawn.new(:white, 5, 1),
      Pawn.new(:white, 6, 1),
      Pawn.new(:white, 7, 1),
      #
      Rook.new(:black, 0, 7),
      Knight.new(:black, 1, 7),
      Bishop.new(:black, 2, 7),
      Queen.new(:black, 3, 7),
      King.new(:black, 4, 7),
      Bishop.new(:black, 5, 7),
      Knight.new(:black, 6, 7),
      Rook.new(:black, 7, 7),
      #
      Pawn.new(:black, 0, 6),
      Pawn.new(:black, 1, 6),
      Pawn.new(:black, 2, 6),
      Pawn.new(:black, 3, 6),
      Pawn.new(:black, 4, 6),
      Pawn.new(:black, 5, 6),
      Pawn.new(:black, 6, 6),
      Pawn.new(:black, 7, 6)
    ]
  end

  def get_piece(board, {column, row}) do
    Enum.find(board, fn piece ->
      piece.column == column && piece.row == row
    end)
  end

  def move_piece(board, from, to) do
    take =
      Enum.find(board, fn piece ->
        Piece.position(piece) == to
      end)

    board =
      board
      |> Enum.reject(fn piece ->
        Piece.position(piece) == to
      end)

    to_update_idx =
      Enum.find_index(board, fn piece ->
        Piece.position(piece) == from
      end)

    board =
      List.update_at(board, to_update_idx, fn piece ->
        Piece.move(piece, to)
      end)

    {board, take}
  end

  def on_board?({column, row}) do
    column <= 7 && row <= 7 && column >= 0 && row >= 0
  end
end

defmodule Chess.BoardTest do
  use ExUnit.Case, async: true

  alias Chess.Board
  alias Chess.Pieces.{King, Queen, Rook, Bishop, Knight, Pawn}
  alias Chess.Piece

  test "new" do
    board = Board.new()

    assert board == [
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

  test "get_piece/2" do
    board = Board.new()

    assert Board.get_piece(board, {4, 4}) == nil
    assert Board.get_piece(board, {7, 6}) == Pawn.new(:black, 7, 6)
    assert Board.get_piece(board, {0, 0}) == Rook.new(:white, 0, 0)
  end

  test "move_piece/3" do
    board = Board.new()

    assert Board.get_piece(board, {4, 1}) == Pawn.new(:white, 4, 1)

    {board, nil} = Board.move_piece(board, {4, 1}, {4, 2})

    assert Board.get_piece(board, {4, 1}) == nil

    assert Piece.position(Board.get_piece(board, {4, 2})) ==
             Piece.position(Pawn.new(:white, 4, 2))
  end

  test "on_board?/1" do
    for column <- 0..7, row <- 0..7 do
      assert Board.on_board?({column, row})
    end

    refute Board.on_board?({-1, 4})
    refute Board.on_board?({1, -4})
  end
end

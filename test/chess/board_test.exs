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

  test "get_pieces/3" do
    board = Board.new()

    assert Board.get_pieces(board, King, :black) == [King.new(:black, 4, 7)]

    assert Board.get_pieces(board, Rook, :white) == [
             Rook.new(:white, 0, 0),
             Rook.new(:white, 7, 0)
           ]

    assert Board.get_pieces(board, Queen, :white) == [Queen.new(:white, 3, 0)]
  end

  describe "calculate_check/1" do
    test "simple check" do
      # ........
      # ........
      # ........
      # ....♚...
      # ...♕....
      # ........
      # ........
      # ........

      board = [
        King.new(:black, 4, 4),
        Queen.new(:white, 3, 3)
      ]

      assert Board.calculate_check(board, :white) == :check
    end

    test "attack out of check" do
      # ........
      # ........
      # ........
      # ........
      # ........
      # ♙♙......
      # ♚.♖.....
      board = [
        King.new(:black, 0, 0),
        Pawn.new(:white, 0, 1),
        Pawn.new(:white, 1, 1),
        Rook.new(:white, 2, 0)
      ]

      assert Board.calculate_check(board, :white) == :check
    end

    test "contained checkmate" do
      # ........
      # ...♟♟♟..
      # ...♟♚♟..
      # ...♟.♟..
      # ........
      # ........
      # ....♕...

      board = [
        King.new(:black, 4, 4),
        Pawn.new(:black, 3, 3),
        Pawn.new(:black, 3, 4),
        Pawn.new(:black, 3, 5),
        Pawn.new(:black, 4, 5),
        Pawn.new(:black, 5, 5),
        Pawn.new(:black, 5, 4),
        Pawn.new(:black, 5, 3),
        Queen.new(:white, 4, 0)
      ]

      assert Board.calculate_check(board, :white) == :checkmate
    end

    test "attack contained checkmate" do
      # ♚.......
      # ........
      # ........
      # ........
      # ........
      # ........
      # ........
      # ♖♖......

      board = [
        King.new(:black, 0, 7),
        Rook.new(:white, 0, 0),
        Rook.new(:white, 1, 0)
      ]

      assert Board.calculate_check(board, :white) == :checkmate
    end

    test "fast mate" do
      # ...♛♚♝..
      # ...♟.♕..
      # ........
      # ........
      # ..♗.....
      # ........
      # ........
      # ........

      board = [
        King.new(:black, 4, 7),
        Queen.new(:black, 3, 7),
        Pawn.new(:black, 3, 6),
        Bishop.new(:black, 5, 7),
        Queen.new(:white, 5, 6),
        Bishop.new(:white, 2, 3)
      ]

      assert Board.calculate_check(board, :white) == :checkmate
    end
  end
end

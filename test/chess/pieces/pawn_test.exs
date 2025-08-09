defmodule Chess.PiecesTest do
  use ExUnit.Case, async: true

  alias Chess.Pieces.{Pawn, Queen}
  alias Chess.Piece

  describe "pawn white" do
    test "when hasn't moved, unobstructed" do
      pawn1 = Pawn.new(:white, 4, 1)

      board = [
        pawn1
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{4, 2}, {4, 3}])
    end

    test "when has moved, unobstructed" do
      pawn1 = Pawn.new(:white, 4, 1)
      pawn1 = Piece.move(pawn1, {4, 2})

      board = [
        pawn1
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{4, 3}])
    end

    test "obstructed" do
      pawn1 = Pawn.new(:white, 4, 1)
      pawn2 = Pawn.new(:black, 4, 2)

      board = [
        pawn1,
        pawn2
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([])
    end

    test "available takes" do
      pawn1 = Pawn.new(:white, 4, 1)
      pawn1 = Piece.move(pawn1, {4, 2})

      pawn2 = Pawn.new(:black, 5, 3)
      pawn3 = Pawn.new(:black, 3, 3)

      board = [
        pawn1,
        pawn2,
        pawn3
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{3, 3}, {5, 3}, {4, 3}])
    end

    test "unavailable takes" do
      pawn1 = Pawn.new(:white, 4, 1)
      pawn1 = Piece.move(pawn1, {4, 2})

      pawn2 = Pawn.new(:white, 5, 3)
      pawn3 = Pawn.new(:white, 3, 3)

      board = [
        pawn1,
        pawn2,
        pawn3
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{4, 3}])
    end

    test "becomes queen" do
      pawn = Pawn.new(:white, 4, 6)

      board = [
        pawn
      ]

      assert Piece.moves(pawn, board) == MapSet.new([{4, 7}])

      assert Piece.move(pawn, {4, 7}) == Queen.new(:white, 4, 7)
    end
  end

  describe "pawn black" do
    test "when hasn't moved, unobstructed" do
      pawn1 = Pawn.new(:black, 4, 6)

      board = [
        pawn1
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{4, 5}, {4, 4}])
    end

    test "when has moved, unobstructed" do
      pawn1 = Pawn.new(:black, 4, 6)
      pawn1 = Piece.move(pawn1, {4, 5})

      board = [
        pawn1
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{4, 4}])
    end

    test "obstructed" do
      pawn1 = Pawn.new(:black, 4, 6)
      pawn2 = Pawn.new(:white, 4, 5)

      board = [
        pawn1,
        pawn2
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([])
    end

    test "available takes" do
      pawn1 = Pawn.new(:black, 4, 6)
      pawn1 = Piece.move(pawn1, {4, 5})

      pawn2 = Pawn.new(:white, 3, 4)
      pawn3 = Pawn.new(:white, 5, 4)

      board = [
        pawn1,
        pawn2,
        pawn3
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{3, 4}, {5, 4}, {4, 4}])
    end

    test "unavailable takes" do
      pawn1 = Pawn.new(:black, 4, 6)
      pawn1 = Piece.move(pawn1, {4, 5})

      pawn2 = Pawn.new(:black, 3, 4)
      pawn3 = Pawn.new(:black, 5, 4)

      board = [
        pawn1,
        pawn2,
        pawn3
      ]

      assert Piece.moves(pawn1, board) == MapSet.new([{4, 4}])
    end

    test "becomes queen" do
      pawn = Pawn.new(:black, 4, 1)

      board = [
        pawn
      ]

      assert Piece.moves(pawn, board) == MapSet.new([{4, 0}])

      assert Piece.move(pawn, {4, 0}) == Queen.new(:black, 4, 0)
    end
  end
end

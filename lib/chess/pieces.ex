# TODO
#
# - [x] track has_moved? state for king, rook, pawn
# - [ ] king: castling
# - [ ] rook: castling
# - [x] pawn: first move
# - [ ] pawn: en passant
# - [ ] pawn: only move diagonal if there is a take available
# - [ ] pawn: only move straight if there is no other piece
# - [x] pawn: queen

defmodule Chess.Pieces do
  alias Chess.{Board, Piece}

  defmodule King do
    defstruct [:color, :column, :row, :has_moved?]

    def new(color, column, row) do
      %__MODULE__{color: color, column: column, row: row}
    end
  end

  defimpl Piece, for: King do
    def moves(piece, board) do
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
      |> Enum.filter(fn position ->
        if other_piece = Board.get_piece(board, position) do
          other_piece.color != piece.color
        else
          Board.on_board?(position)
        end
      end)
      |> MapSet.new()
    end

    def position(self) do
      {self.column, self.row}
    end

    def repr(self) do
      case self.color do
        :black -> "♚"
        :white -> "♔"
      end
    end

    def move(piece, {column, row}) do
      %{piece | column: column, row: row, has_moved?: true}
    end
  end

  defmodule Queen do
    defstruct [:color, :column, :row]

    def new(color, column, row) do
      %__MODULE__{color: color, column: column, row: row}
    end
  end

  defimpl Piece, for: Queen do
    def moves(self, board) do
      rook_moves =
        Chess.Pieces.Rook.new(self.color, self.column, self.row)
        |> Piece.moves(board)

      bishop_moves =
        Chess.Pieces.Bishop.new(self.color, self.column, self.row)
        |> Piece.moves(board)

      MapSet.union(rook_moves, bishop_moves)
    end

    def position(self) do
      {self.column, self.row}
    end

    def repr(self) do
      case self.color do
        :black -> "♛"
        :white -> "♕"
      end
    end

    def move(piece, {column, row}) do
      %{piece | column: column, row: row}
    end
  end

  defmodule Rook do
    defstruct [:color, :column, :row, :has_moved?]

    def new(color, column, row) do
      %__MODULE__{color: color, column: column, row: row}
    end
  end

  defimpl Piece, for: Rook do
    def moves(piece, board) do
      [
        fn {column, row} ->
          {column + 1, row}
        end,
        fn {column, row} ->
          {column - 1, row}
        end,
        fn {column, row} ->
          {column, row + 1}
        end,
        fn {column, row} ->
          {column, row - 1}
        end
      ]
      |> Enum.flat_map(fn f ->
        piece
        |> Piece.position()
        |> Stream.iterate(f)
        |> Stream.drop(1)
        |> Enum.reduce_while([], fn position, acc ->
          if other_piece = Board.get_piece(board, position) do
            if other_piece.color != piece.color do
              {:halt, [position | acc]}
            else
              {:halt, acc}
            end
          else
            if Board.on_board?(position) do
              {:cont, [position | acc]}
            else
              {:halt, acc}
            end
          end
        end)
      end)
      |> MapSet.new()
    end

    def position(self) do
      {self.column, self.row}
    end

    def repr(self) do
      case self.color do
        :black -> "♜"
        :white -> "♖"
      end
    end

    def move(piece, {column, row}) do
      %{piece | column: column, row: row, has_moved?: true}
    end
  end

  defmodule Bishop do
    defstruct [:color, :column, :row]

    def new(color, column, row) do
      %__MODULE__{color: color, column: column, row: row}
    end
  end

  defimpl Piece, for: Bishop do
    def moves(piece, board) do
      [
        fn {column, row} ->
          {column + 1, row + 1}
        end,
        fn {column, row} ->
          {column + 1, row - 1}
        end,
        fn {column, row} ->
          {column - 1, row + 1}
        end,
        fn {column, row} ->
          {column - 1, row - 1}
        end
      ]
      |> Enum.flat_map(fn f ->
        piece
        |> Piece.position()
        |> Stream.iterate(f)
        |> Stream.drop(1)
        |> Enum.reduce_while([], fn position, acc ->
          if other_piece = Board.get_piece(board, position) do
            if other_piece.color != piece.color do
              {:halt, [position | acc]}
            else
              {:halt, acc}
            end
          else
            if Board.on_board?(position) do
              {:cont, [position | acc]}
            else
              {:halt, acc}
            end
          end
        end)
      end)
      |> MapSet.new()
    end

    def position(self) do
      {self.column, self.row}
    end

    def repr(self) do
      case self.color do
        :black -> "♝"
        :white -> "♗"
      end
    end

    def move(piece, {column, row}) do
      %{piece | column: column, row: row}
    end
  end

  defmodule Knight do
    defstruct [:color, :column, :row]

    def new(color, column, row) do
      %__MODULE__{color: color, column: column, row: row}
    end
  end

  defimpl Piece, for: Knight do
    def moves(piece, board) do
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
      |> Enum.filter(fn position ->
        if other_piece = Board.get_piece(board, position) do
          other_piece.color != piece.color
        else
          Board.on_board?(position)
        end
      end)
      |> MapSet.new()
    end

    def position(self) do
      {self.column, self.row}
    end

    def repr(self) do
      case self.color do
        :black -> "♞"
        :white -> "♘"
      end
    end

    def move(piece, {column, row}) do
      %{piece | column: column, row: row}
    end
  end

  defmodule Pawn do
    defstruct [:color, :column, :row, :has_moved?]

    def new(color, column, row) do
      %__MODULE__{color: color, column: column, row: row}
    end
  end

  defimpl Piece, for: Pawn do
    def moves(piece, board) do
      # pawns can only move forward...
      row_op =
        case piece.color do
          :white -> :+
          :black -> :-
        end

      possible_moves =
        if piece.has_moved? do
          [
            {piece.column + 1, apply(Kernel, row_op, [piece.row, 1])},
            {piece.column - 1, apply(Kernel, row_op, [piece.row, 1])},
            {piece.column, apply(Kernel, row_op, [piece.row, 1])}
          ]
        else
          # pawns can move 2 on the first move
          [
            {piece.column + 1, apply(Kernel, row_op, [piece.row, 1])},
            {piece.column - 1, apply(Kernel, row_op, [piece.row, 1])},
            {piece.column, apply(Kernel, row_op, [piece.row, 1])},
            {piece.column, apply(Kernel, row_op, [piece.row, 2])}
          ]
        end

      # TODO en passant

      possible_moves
      |> Enum.filter(&Board.on_board?(&1))
      |> Enum.filter(fn position ->
        if other_piece = Board.get_piece(board, position) do
          other_piece.color != piece.color
        else
          true
        end
      end)
      |> MapSet.new()
    end

    def position(piece) do
      {piece.column, piece.row}
    end

    def repr(piece) do
      case piece.color do
        :black -> "♟"
        :white -> "♙"
      end
    end

    def move(piece, {column, row}) do
      new = %{piece | column: column, row: row, has_moved?: true}

      if new.row == 0 || new.row == 7 do
        Queen.new(new.color, new.column, new.row)
      else
        new
      end
    end
  end
end

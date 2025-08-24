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

  def update_with_moves(board, moves) do
    Enum.reduce(moves, {board, []}, fn {from, to}, {board, takes} ->
      {board, take} =
        move_piece(
          board,
          from,
          to
        )

      if take do
        {board, [take | takes]}
      else
        {board, takes}
      end
    end)
  end

  def get_piece(board, {column, row} = _position) do
    Enum.find(board, fn piece ->
      piece.column == column && piece.row == row
    end)
  end

  def calculate_check(board, attacking_color) do
    my_pieces = Enum.filter(board, fn piece -> piece.color == attacking_color end)

    enemy_king =
      get_king(
        board,
        case attacking_color do
          :white -> :black
          :black -> :white
        end
      )

    enemy_king_position = Piece.position(enemy_king)

    all_my_moves =
      my_pieces
      |> Enum.flat_map(fn
        %Pawn{} = piece -> Pawn.attacks_naive(piece)
        piece -> Piece.moves(piece, board)
      end)
      |> MapSet.new()

    if MapSet.member?(all_my_moves, enemy_king_position) do
      king_moves = Piece.moves(enemy_king, board)

      cond do
        Enum.empty?(king_moves) ->
          :checkmate

        Enum.all?(king_moves, fn king_move ->
          calculate_check_once(
            move_piece(board, {enemy_king.column, enemy_king.row}, king_move)
            |> elem(0),
            attacking_color
          ) in [:check, :checkmate]
        end) ->
          :checkmate

        true ->
          :check
      end
    else
      nil
    end
  end

  defp calculate_check_once(board, attacking_color) do
    my_pieces = Enum.filter(board, fn piece -> piece.color == attacking_color end)

    enemy_king =
      get_king(
        board,
        case attacking_color do
          :black -> :white
          :white -> :black
        end
      )

    enemy_king_position = Piece.position(enemy_king)

    all_my_moves =
      my_pieces
      |> Enum.flat_map(fn
        %Pawn{} = piece -> Pawn.attacks_naive(piece)
        piece -> Piece.moves(piece, board)
      end)
      |> MapSet.new()

    if MapSet.member?(all_my_moves, enemy_king_position) do
      king_moves = Piece.moves(enemy_king, board)

      cond do
        Enum.empty?(king_moves) ->
          :checkmate

        Enum.all?(king_moves, fn king_move ->
          MapSet.member?(all_my_moves, king_move)
        end) ->
          :checkmate

        true ->
          :check
      end
    else
      nil
    end
  end

  def get_king(board, color) do
    [king] = get_pieces(board, King, color)
    king
  end

  def get_pieces(board, kind, color) do
    board
    |> Enum.filter(fn piece ->
      case piece do
        %^kind{} when piece.color == color -> true
        _ -> false
      end
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

  def render(board) do
    for row <- 7..0//-1 do
      for column <- 0..7 do
        piece =
          Enum.find(board, fn piece ->
            piece.column == column && piece.row == row
          end)

        if piece do
          Piece.repr(piece)
        else
          "."
        end
      end
      |> Enum.join()
    end
    |> Enum.join("\n")
  end
end

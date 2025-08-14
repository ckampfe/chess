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

  def calculate_check(board) do
    # for all pieces
    # is the opposite king attacked
    # if so, can the king move?
    # if so, can the player attack the piece that is causing the check?
    # (is attacking piece in the attacking moves of the player?)
    # if the king can move, is it in check again?
    # if the king cannot move out or all move outs are in check, checkmate
    white_pieces = Enum.filter(board, fn piece -> piece.color == :white end)
    black_king = get_king(board, :black)
    king_position = Piece.position(black_king)

    # TODO we need Piece.moves and Piece.attacks,
    # so we can get hypothetical attacks for all pieces
    # AND PAWNS, since Piece.moves will not show a valid
    # attack if there is no enemy piece there
    all_white_moves =
      white_pieces
      |> Enum.flat_map(fn
        %Pawn{} = piece -> Pawn.attacks_naive(piece)
        piece -> Piece.moves(piece, board)
      end)
      |> MapSet.new()

    if MapSet.member?(all_white_moves, king_position) do
      king_moves = Piece.moves(black_king, board)

      cond do
        Enum.empty?(king_moves) ->
          :checkmate

        Enum.all?(king_moves, fn king_move ->
          calculate_check_once(
            move_piece(board, {black_king.column, black_king.row}, king_move)
            |> elem(0)
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

  defp calculate_check_once(board) do
    white_pieces = Enum.filter(board, fn piece -> piece.color == :white end)
    black_king = get_king(board, :black)
    king_position = Piece.position(black_king)

    all_white_moves =
      white_pieces
      |> Enum.flat_map(fn
        %Pawn{} = piece -> Pawn.attacks_naive(piece)
        piece -> Piece.moves(piece, board)
      end)
      |> MapSet.new()

    if MapSet.member?(all_white_moves, king_position) do
      king_moves = Piece.moves(black_king, board)

      cond do
        Enum.empty?(king_moves) ->
          :checkmate

        Enum.all?(king_moves, fn king_move ->
          MapSet.member?(all_white_moves, king_move)
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

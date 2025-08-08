# TODO
#
# - [ ] named games
# - [ ] games persist state
# - [x] most moves
# - [ ] special moves (castle, en passant, etc)
# - [ ] list of takes
# - [ ] turns

defmodule ChessWeb.GameLive.Play do
  use ChessWeb, :live_view

  alias Chess.{Board, Piece}

  require Logger

  def mount(params, _session, socket) do
    playing_as =
      case Map.fetch!(params, "playing_as") do
        "white" -> :white
        "black" -> :black
      end

    board = Board.new()

    {board, row_numbers} =
      if playing_as == :black do
        {board, 0..7}
      else
        {Enum.reverse(board), 7..0//-1}
      end

    socket =
      socket
      |> assign(:playing_as, playing_as)
      |> assign(:moves, [])
      |> assign(:board, board)
      |> assign(:row_numbers, row_numbers)
      |> assign(:selected_piece, nil)
      |> assign(:potential_moves, MapSet.new())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex justify-center my-4">
      <div class="border-solid border-2 aspect-square w-160">
        <div
          :for={
            {row, start_color} <-
              Enum.zip([@row_numbers, background_color_stream(:light)])
          }
          class="flex"
        >
          <span
            :for={
              {column, square_color} <-
                Enum.zip([0..7, background_color_stream(start_color)])
            }
            class={"
            #{background_color({column, row}, @selected_piece, @potential_moves, square_color)}
            w-20 aspect-square flex items-center justify-center select-none"}
            phx-click={"select-position-#{column}-#{row}"}
          >
            {if piece = Board.get_piece(@board, {column, row}) do
              Piece.repr(piece)
            else
              ""
            end}
          </span>
        </div>
      </div>
    </div>
    """
  end

  def handle_event(
        <<"select-position-", column::binary-1, "-", row::binary-1>>,
        _unsigned_params,
        socket
      ) do
    column = String.to_integer(column)
    row = String.to_integer(row)

    socket =
      if socket.assigns.selected_piece do
        cond do
          {column, row} == Piece.position(socket.assigns.selected_piece) ->
            socket
            |> assign(:selected_piece, nil)
            |> assign(:potential_moves, MapSet.new())

          MapSet.member?(socket.assigns.potential_moves, {column, row}) ->
            {board, piece_taken} =
              Board.move_piece(
                socket.assigns.board,
                Piece.position(socket.assigns.selected_piece),
                {column, row}
              )

            dbg(piece_taken)

            socket
            |> update(:moves, fn moves ->
              [{Piece.position(socket.assigns.selected_piece), {column, row}} | moves]
            end)
            |> assign(:selected_piece, nil)
            |> assign(:board, board)
            |> assign(:potential_moves, MapSet.new())
        end
      else
        cond do
          piece = my_piece?(socket.assigns.board, {column, row}, socket.assigns.playing_as) ->
            socket
            |> assign(:selected_piece, piece)
            |> assign(
              :potential_moves,
              Piece.moves(piece, socket.assigns.board)
            )

          true ->
            socket
        end
      end

    {:noreply, socket}
  end

  defp my_piece?(board, position, playing_as) do
    if piece = Board.get_piece(board, position) do
      if piece.color == playing_as do
        piece
      else
        nil
      end
    end
  end

  defp background_color(
         position,
         selected,
         potential_moves,
         fallback_color
       ) do
    cond do
      # and is piece
      position == selected || MapSet.member?(potential_moves, position) ->
        "bg-pink-400"

      fallback_color == :light ->
        "bg-gray-50"

      true ->
        "bg-gray-400"
    end
  end

  defp background_color_stream(start_color) do
    Stream.iterate(start_color, fn
      :light -> :dark
      :dark -> :light
    end)
  end
end

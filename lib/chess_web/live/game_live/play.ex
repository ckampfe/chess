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

    socket =
      socket
      |> assign(:playing_as, playing_as)
      |> assign(:moves, [])
      |> assign(
        :board,
        Board.new()
      )
      |> assign(:selected, nil)
      |> assign(:potential_moves, MapSet.new())

    {:ok, socket}
  end

  def render(assigns) do
    Logger.debug(assigns)

    {board, row_numbers} =
      if assigns.playing_as == :black do
        {assigns.board, 0..7}
      else
        {Enum.reverse(assigns.board), 7..0//-1}
      end

    assigns =
      assigns
      |> assign(:board, board)
      |> assign(:row_numbers, row_numbers)

    ~H"""
    <div class="flex justify-center">
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
            #{background_color({column, row}, @selected, @playing_as, @potential_moves, square_color)}
            w-20 aspect-square flex items-center justify-center"}
            phx-click={"select-position-#{column}-#{row}"}
          >
            {Piece.repr(Board.get(@board, {column, row}))}
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
      if socket.assigns.selected do
        cond do
          {column, row} == socket.assigns.selected ->
            socket
            |> assign(:selected, nil)
            |> assign(:potential_moves, MapSet.new())

          MapSet.member?(socket.assigns.potential_moves, {column, row}) ->
            # perform move
            socket
        end
      else
        cond do
          my_piece?(socket.assigns.board, {column, row}, socket.assigns.playing_as) ->
            socket
            |> assign(:selected, {column, row})
            |> assign(
              :potential_moves,
              Board.moves_for_piece(socket.assigns.board, {column, row})
            )

          true ->
            socket
        end
      end

    {:noreply, socket}
  end

  defp my_piece?(board, {column, row} = position, playing_as) do
    piece = Board.get(board, position)

    piece.color == playing_as
  end

  defp background_color(
         {column, row} = position,
         selected,
         playing_as,
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

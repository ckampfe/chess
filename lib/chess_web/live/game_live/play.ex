# TODO
#
# - [ ] named games
# - [ ] load game state on mount
# - [x] most moves
# - [ ] special moves (castle, en passant, etc)
# - [x] display list of takes
# - [ ] compute takes list on mount
# - [ ] chat
# - [ ] redirect all non-players to a spectator endpoint
# - [x] turns
# - [ ] checkmate

defmodule ChessWeb.GameLive.Play do
  use ChessWeb, :live_view

  alias Chess.{Board, Piece}

  require Logger

  def mount(%{"game_id" => game_id} = params, _session, socket) do
    game_topic = "#{game_id}:game_events"

    :ok = Phoenix.PubSub.subscribe(Chess.PubSub, game_topic)

    playing_as =
      case Map.fetch!(params, "playing_as") do
        "white" ->
          Phoenix.PubSub.broadcast(Chess.PubSub, game_topic, :white_taken)
          :white

        "black" ->
          Phoenix.PubSub.broadcast(Chess.PubSub, game_topic, :black_taken)
          :black
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
      |> assign(:to_move, :white)
      |> assign(:game_id, game_id)
      |> assign(:game_topic, game_topic)
      |> assign(:playing_as, playing_as)
      |> assign(:moves, [])
      |> assign(:takes_white, [])
      |> assign(:takes_black, [])
      |> assign(:board, board)
      |> assign(:row_numbers, row_numbers)
      |> assign(:selected_piece, nil)
      |> assign(:potential_moves, MapSet.new())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h3 class="m-4">to move: {@to_move}</h3>
    <div class="sm:grid sm:grid-cols-7 sm:grid-rows-1 gap-4">
      <div id="takes" class="sm:order-3 sm:col-span-1 grid grid-cols-1 gap-y-4">
        <div>
          <span :for={piece <- if(@playing_as == :white, do: @takes_black, else: @takes_white)}>
            {Piece.repr(piece)}
          </span>
        </div>
        <div>
          <span :for={piece <- if(@playing_as == :white, do: @takes_white, else: @takes_black)}>
            {Piece.repr(piece)}
          </span>
        </div>
      </div>
      <div class="sm:order-2 sm:col-span-4 m-6 sm:m-2 items-center justify-center">
        <div class="border-solid border-2 aspect-square min-w-80">
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
            flex basis-1/8 aspect-square select-none items-center justify-center"}
              phx-click={@to_move == @playing_as && "select-position-#{column}-#{row}"}
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
      <div id="chat" class="sm:order-1 sm:col-span-2">chat</div>
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

    to = {column, row}

    socket =
      if socket.assigns.selected_piece do
        cond do
          to == Piece.position(socket.assigns.selected_piece) ->
            socket
            |> assign(:selected_piece, nil)
            |> assign(:potential_moves, MapSet.new())

          MapSet.member?(socket.assigns.potential_moves, to) ->
            {board, piece_taken} =
              Board.move_piece(
                socket.assigns.board,
                Piece.position(socket.assigns.selected_piece),
                to
              )

            Phoenix.PubSub.broadcast(
              Chess.PubSub,
              socket.assigns.game_topic,
              {
                :move,
                socket.assigns.playing_as,
                Piece.position(socket.assigns.selected_piece),
                to
              }
            )

            takes_key =
              if socket.assigns.playing_as == :white do
                :takes_white
              else
                :takes_black
              end

            socket
            |> update(:moves, fn moves ->
              [{Piece.position(socket.assigns.selected_piece), to} | moves]
            end)
            |> update(:to_move, fn to_move ->
              if to_move == :white do
                :black
              else
                :white
              end
            end)
            |> assign(:selected_piece, nil)
            |> assign(:board, board)
            |> assign(:potential_moves, MapSet.new())
            |> update(takes_key, fn takes ->
              if piece_taken do
                [piece_taken | takes]
              else
                takes
              end
            end)
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

  def handle_info(:black_taken, socket) do
    # TODO register as taken
    {:noreply, socket}
  end

  def handle_info(:white_taken, socket) do
    # TODO register as taken
    {:noreply, socket}
  end

  def handle_info({:move, who, from, to} = m, socket) do
    if who == socket.assigns.playing_as do
      # do nothing, that was my move
      {:noreply, socket}
    else
      # TODO record piece_tao
      {board, piece_taken} =
        Board.move_piece(
          socket.assigns.board,
          from,
          to
        )

      takes_key =
        if socket.assigns.playing_as == :white do
          :takes_black
        else
          :takes_white
        end

      socket =
        socket
        |> update(:moves, fn moves ->
          [{from, to} | moves]
        end)
        |> assign(:to_move, socket.assigns.playing_as)
        |> assign(:board, board)
        |> update(takes_key, fn takes ->
          if piece_taken do
            [piece_taken | takes]
          else
            takes
          end
        end)

      {:noreply, socket}
    end
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

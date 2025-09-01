# TODO
#
# - [ ] named games
# - [x] load game state on mount
# - [x] most moves
# - [ ] special moves (castle, en passant, etc)
# - [x] display list of takes
# - [x] compute takes list on mount
# - [x] chat
# - [ ] redirect all non-players to a spectator endpoint
# - [x] turns
# - [x] check
# - [x] checkmate
# - [x] fix board being incorrectly mirrored. is this only
#       a view problem, or a data storage problem?
# - [x] fix allowing moves that do not get king out of check
# - [ ] do not allow the king to move into check

defmodule ChessWeb.GameLive.Play do
  use ChessWeb, :live_view

  alias Chess.{Board, Piece, Move, Repo, ChatMessage}

  import Ecto.Query

  require Logger

  def mount(params, _session, socket) do
    params_types = %{
      game_id: Ecto.UUID,
      playing_as: Ecto.ParameterizedType.init(Ecto.Enum, values: [:white, :black, :spectate])
    }

    validated_params =
      Ecto.Changeset.cast({%{}, params_types}, params, Map.keys(params_types))
      |> Ecto.Changeset.validate_required([:game_id])
      |> Ecto.Changeset.apply_action!(nil)

    game_id = Map.fetch!(validated_params, :game_id)
    playing_as = Map.get(validated_params, :playing_as)

    if playing_as && connected?(socket) do
      case Registry.lookup(Chess.Registry, game_id) do
        [] ->
          Registry.register(Chess.Registry, game_id, playing_as)

        entries ->
          if Enum.any?(entries, fn {other_pid, other_playing_as} ->
               other_pid != self() && other_playing_as != :spectate &&
                 other_playing_as == playing_as
             end) do
            # figure out how to error, we are trying to double register
            raise "TODO; cannot play as already claimed color - this is a bug"
          else
            Registry.register(Chess.Registry, game_id, playing_as)
          end
      end
    end

    game_topic = "#{validated_params.game_id}:game_events"

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Chess.PubSub, game_topic)
    end

    if playing_as && connected?(socket) do
      Phoenix.PubSub.broadcast(Chess.PubSub, game_topic, {:playing_as, playing_as})
    end

    board = Board.new()

    {board, row_numbers, column_numbers} =
      if playing_as == :black do
        {board, 0..7, 7..0//-1}
      else
        {Enum.reverse(board), 7..0//-1, 0..7}
      end

    moves =
      Move
      |> where([m], m.game_id == ^game_id)
      |> order_by([m], asc: m.inserted_at)
      |> select([m], {{m.from_column, m.from_row}, {m.to_column, m.to_row}})
      |> Repo.all()

    chat_messages =
      ChatMessage
      |> where([m], m.game_id == ^game_id)
      |> order_by([m], asc: m.inserted_at)
      |> select([m], %{timestamp: m.inserted_at, who: m.who, body: m.body})
      |> Repo.all()

    largest_spectator_id =
      ChatMessage
      |> where([m], m.game_id == ^game_id)
      |> where([m], like(m.who, "spectate%"))
      |> order_by([m], desc: m.inserted_at)
      |> select([m], fragment("substring(?, 10, -1)", m.who))
      |> limit(1)
      |> Repo.one()

    spectator_id =
      if largest_spectator_id do
        String.to_integer(largest_spectator_id) + 1
      else
        1
      end

    nick =
      if playing_as == :spectate do
        "spectate#{spectator_id}"
      else
        to_string(playing_as)
      end

    {board, takes} = Board.update_with_moves(board, moves)

    takes_by_color =
      Enum.group_by(takes, fn piece ->
        piece.color
      end)

    to_move =
      if rem(Enum.count(moves), 2) == 0 do
        :white
      else
        :black
      end

    chat_input_form = to_form(%{"input" => {}})

    uri = Phoenix.LiveView.get_connect_info(socket, :uri)

    game_link =
      if uri do
        if uri.port do
          "#{uri.scheme}://#{uri.host}:#{uri.port}/games/#{game_id}/play"
        else
          "#{uri.scheme}://#{uri.host}/games/#{game_id}/play"
        end
      else
        ""
      end

    claimed_colors =
      Chess.Registry
      |> Registry.lookup(game_id)
      |> Enum.map(fn {_pid, claimed_color} -> claimed_color end)
      |> MapSet.new()

    available_to_play_as = MapSet.difference(MapSet.new([:black, :white]), claimed_colors)

    socket =
      socket
      |> assign(:to_move, to_move)
      |> assign(:game_id, game_id)
      |> assign(:game_topic, game_topic)
      |> assign(:playing_as, playing_as)
      |> assign(:check_status, nil)
      |> assign(:moves, moves)
      |> assign(:takes_white, Map.get(takes_by_color, :black, []))
      |> assign(:takes_black, Map.get(takes_by_color, :white, []))
      |> assign(:board, board)
      |> assign(:column_numbers, column_numbers)
      |> assign(:row_numbers, row_numbers)
      |> assign(:selected_piece, nil)
      |> assign(:potential_moves, MapSet.new())
      |> assign(:chat_messages, chat_messages)
      |> assign(:chat_input_form, chat_input_form)
      |> assign(:game_link, game_link)
      |> assign(:available_to_play_as, available_to_play_as)
      |> assign(:nick, nick)

    socket =
      case Board.calculate_check(
             board,
             case to_move do
               :white -> :black
               :black -> :white
             end
           ) do
        :checkmate ->
          socket
          |> assign(:to_move, nil)
          |> assign(:check_status, :checkmate)

        :check ->
          assign(socket, :check_status, :check)

        _ ->
          assign(socket, :check_status, nil)
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-h-screen m-2">
      <%= if @playing_as do %>
        <a
          class="underline text-blue-600 hover:text-blue-800 visited:text-purple-600"
          phx-click={JS.dispatch("phx:copy", to: "#game-link")}
        >
          copy game link to clipboard
        </a>
        <input
          :if={@game_link}
          type="hidden"
          value={@game_link}
          id="game-link"
        />

        <h1 :if={@check_status}>{@check_status}</h1>
        <h3 class="m-4">to move: {@to_move}</h3>
        <div class="sm:grid sm:grid-cols-7 sm:grid-rows-1 gap-4">
          <.takes
            playing_as={@playing_as}
            takes_black={@takes_black}
            takes_white={@takes_white}
            class="sm:order-3 sm:col-span-1 grid grid-cols-1 gap-y-4"
          />
          <.board
            column_numbers={@column_numbers}
            row_numbers={@row_numbers}
            selected_piece={@selected_piece}
            potential_moves={@potential_moves}
            to_move={@to_move}
            playing_as={@playing_as}
            board={@board}
            class="sm:order-2 sm:col-span-4 m-6 sm:m-2 items-center justify-center"
          />
          <.chat
            chat_messages={@chat_messages}
            chat_input_form={@chat_input_form}
            class="sm:order-1 sm:col-span-2 sm:max-h-screen"
          />
        </div>
      <% else %>
        <dialog
          :if={!@playing_as}
          phx-mounted={JS.dispatch("chess:show-modal")}
          class="m-auto mt-8 rounded-xl bg-white p-6 shadow-3xl backdrop:bg-black/50 backdrop:backdrop-blur-md"
        >
          <p>Choose your character!</p>
          <.button
            href={~p"/games/#{@game_id}/play?playing_as=black"}
            disabled={!MapSet.member?(@available_to_play_as, :black)}
          >
            Black
          </.button>
          <.button
            href={~p"/games/#{@game_id}/play?playing_as=white"}
            disabled={!MapSet.member?(@available_to_play_as, :white)}
          >
            White
          </.button>
          <.button href={~p"/games/#{@game_id}/play?playing_as=spectate"}>Spectate</.button>
        </dialog>
      <% end %>
    </div>
    """
  end

  attr :playing_as, :atom, values: [:black, :white]
  attr :takes_black, :list
  attr :takes_white, :list
  attr :rest, :global

  def takes(assigns) do
    ~H"""
    <div id="takes" {@rest}>
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
    """
  end

  attr :board, :list
  attr :playing_as, :atom, values: [:black, :white]
  attr :to_move, :atom, values: [:black, :white]
  attr :potential_moves, MapSet
  attr :selected_piece, Piece
  attr :column_numbers, :list
  attr :row_numbers, :list
  attr :rest, :global

  def board(assigns) do
    ~H"""
    <div id="board" {@rest}>
      <div class="border-solid border-2 aspect-square min-w-80">
        <div
          :for={row <- @row_numbers}
          class="flex"
        >
          <span
            :for={column <- @column_numbers}
            class={"
            #{background_color({column, row}, @selected_piece, @potential_moves, if(rem(column + row, 2) == 0, do: :dark, else: :light))}
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
    """
  end

  attr :chat_input_form, Phoenix.HTML.Form
  attr :chat_messages, :list
  attr :rest, :global

  def chat(assigns) do
    ~H"""
    <div id="chat" {@rest}>
      <div
        class="overflow-y-scroll max-h-72 sm:max-h-8/10"
        id="chat-scroller"
        phx-hook="ScrollToBottom"
      >
        <div :for={message <- @chat_messages}>
          <div>
            <span class="text-lg">{message.who}</span>
            <span class="text-xs">{message.timestamp}</span>
          </div>
          <div>{message.body}</div>
        </div>
      </div>
      <.form for={@chat_input_form} phx-change="update-chat-input" phx-submit="send-chat-message">
        <.input type="text" field={@chat_input_form[:chat_input]} required />
        <.button>
          Send
        </.button>
      </.form>
    </div>
    """
  end

  # this is the case where a piece is currently selected
  def handle_event(
        <<"select-position-", column::binary-1, "-", row::binary-1>>,
        _unsigned_params,
        %{assigns: %{selected_piece: selected_piece}} = socket
      )
      when not is_nil(selected_piece) do
    params_types = %{
      column: :integer,
      row: :integer
    }

    %{column: column, row: row} =
      Ecto.Changeset.cast(
        {%{}, params_types},
        %{column: column, row: row},
        Map.keys(params_types)
      )
      |> Ecto.Changeset.validate_number(:column,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 7
      )
      |> Ecto.Changeset.validate_number(:row,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 7
      )
      |> Ecto.Changeset.validate_required(Map.keys(params_types))
      |> Ecto.Changeset.apply_action!(nil)

    to = {column, row}

    socket =
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

          {from_column, from_row} = Piece.position(socket.assigns.selected_piece)

          %Move{
            from_column: from_column,
            from_row: from_row,
            to_column: column,
            to_row: row,
            game_id: socket.assigns.game_id
          }
          |> Repo.insert!()

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

          socket =
            socket
            |> Phoenix.Component.update(:moves, fn moves ->
              [{Piece.position(socket.assigns.selected_piece), to} | moves]
            end)
            |> Phoenix.Component.update(:to_move, fn to_move ->
              if to_move == :white do
                :black
              else
                :white
              end
            end)
            |> assign(:selected_piece, nil)
            |> assign(:board, board)
            |> assign(:potential_moves, MapSet.new())
            |> Phoenix.Component.update(takes_key, fn takes ->
              if piece_taken do
                [piece_taken | takes]
              else
                takes
              end
            end)

          case Board.calculate_check(board, socket.assigns.playing_as) do
            :checkmate ->
              socket
              |> assign(:to_move, nil)
              |> assign(:check_status, :checkmate)

            :check ->
              assign(socket, :check_status, :check)

            _ ->
              assign(socket, :check_status, nil)
          end
      end

    {:noreply, socket}
  end

  # this is the case where no piece is currently selected
  def handle_event(
        <<"select-position-", column::binary-1, "-", row::binary-1>>,
        _unsigned_params,
        %{assigns: %{selected_piece: nil}} = socket
      ) do
    params_types = %{
      column: :integer,
      row: :integer
    }

    %{column: column, row: row} =
      Ecto.Changeset.cast(
        {%{}, params_types},
        %{column: column, row: row},
        Map.keys(params_types)
      )
      |> Ecto.Changeset.validate_number(:column,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 7
      )
      |> Ecto.Changeset.validate_number(:row,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 7
      )
      |> Ecto.Changeset.validate_required(Map.keys(params_types))
      |> Ecto.Changeset.apply_action!(nil)

    socket =
      if piece =
           get_piece_if_mine(socket.assigns.board, {column, row}, socket.assigns.playing_as) do
        potential_moves = Piece.moves(piece, socket.assigns.board)

        case socket.assigns.check_status do
          :check ->
            # if we are in check, the only legal moves
            # are moves that get us out of check
            moves_that_get_us_out_of_check =
              Enum.filter(potential_moves, fn potential_move ->
                {board, _piece_taken} =
                  Board.move_piece(
                    socket.assigns.board,
                    {column, row},
                    potential_move
                  )

                case Board.calculate_check(
                       board,
                       case socket.assigns.playing_as do
                         :white -> :black
                         :black -> :white
                       end
                     ) do
                  :check -> nil
                  :checkmate -> nil
                  nil -> true
                end
              end)
              |> MapSet.new()

            if !Enum.empty?(moves_that_get_us_out_of_check) do
              socket
              |> assign(:selected_piece, piece)
              |> assign(:potential_moves, moves_that_get_us_out_of_check)
            else
              socket
            end

          _ ->
            socket
            |> assign(:selected_piece, piece)
            |> assign(
              :potential_moves,
              potential_moves
            )
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("update-chat-input", params, socket) do
    chat_input_form = to_form(params)
    {:noreply, assign(socket, :chat_input_form, chat_input_form)}
  end

  def handle_event("send-chat-message", %{"chat_input" => chat_input}, socket) do
    out =
      %ChatMessage{
        game_id: socket.assigns.game_id,
        who: socket.assigns.nick,
        body: chat_input
      }
      |> Repo.insert!(returning: [:inserted_at, :who, :body])

    chat_message = %{timestamp: out.inserted_at, who: out.who, body: out.body}

    socket =
      socket
      |> assign(:chat_input_form, to_form(%{}))
      |> Phoenix.Component.update(:chat_messages, fn chat_messages ->
        chat_messages ++ [chat_message]
      end)

    Phoenix.PubSub.broadcast(
      Chess.PubSub,
      socket.assigns.game_topic,
      {:chat_message, chat_message, socket.assigns.nick}
    )

    {:noreply, socket}
  end

  def handle_info({:chat_message, chat_message, nick}, socket) do
    socket =
      if nick != socket.assigns.nick do
        Phoenix.Component.update(socket, :chat_messages, fn chat_messages ->
          chat_messages ++ [chat_message]
        end)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({:playing_as, _color}, socket) do
    # TODO register as taken
    {:noreply, socket}
  end

  def handle_info({:move, who, from, to}, socket) do
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
        |> Phoenix.Component.update(:moves, fn moves ->
          [{from, to} | moves]
        end)
        |> assign(:to_move, socket.assigns.playing_as)
        |> assign(:board, board)
        |> Phoenix.Component.update(takes_key, fn takes ->
          if piece_taken do
            [piece_taken | takes]
          else
            takes
          end
        end)

      socket =
        case Board.calculate_check(
               board,
               case socket.assigns.playing_as do
                 :black -> :white
                 :white -> :black
               end
             ) do
          :checkmate ->
            socket
            |> assign(:to_move, nil)
            |> assign(:check_status, :checkmate)

          :check ->
            assign(socket, :check_status, :check)

          _ ->
            assign(socket, :check_status, nil)
        end

      {:noreply, socket}
    end
  end

  defp get_piece_if_mine(board, position, playing_as) do
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
end

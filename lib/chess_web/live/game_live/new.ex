defmodule ChessWeb.GameLive.New do
  use ChessWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      Play as:
      <div>
        <.button phx-click="new-game" phx-value-playing_as="black">Black</.button>
        <.button phx-click="new-game" phx-value-playing_as="white">White</.button>
      </div>
    </div>
    """
  end

  def handle_event("new-game", %{"playing_as" => color}, socket) do
    # TODO: is this good?
    # TODO: database stuff instead?
    game = Ecto.UUID.generate()

    socket =
      socket
      |> push_navigate(to: "/games/#{game}/play?playing_as=#{color}")

    {:noreply, socket}
  end
end

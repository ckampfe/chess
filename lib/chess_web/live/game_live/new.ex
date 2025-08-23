defmodule ChessWeb.GameLive.New do
  use ChessWeb, :live_view
  alias Chess.{Game, Repo}

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
    game =
      Repo.insert!(%Game{}, returning: [:id])

    socket =
      socket
      |> push_navigate(to: "/games/#{game.id}/play?playing_as=#{color}")

    {:noreply, socket}
  end
end

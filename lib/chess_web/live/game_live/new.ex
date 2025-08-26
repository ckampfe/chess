defmodule ChessWeb.GameLive.New do
  use ChessWeb, :live_view
  alias Chess.{Game, Repo}

  def render(assigns) do
    ~H"""
    <div>
      Play as:
      <dialog
        class="m-auto mt-8 rounded-xl bg-white p-6 shadow-3xl backdrop:bg-black/50 backdrop:backdrop-blur-md"
        phx-mounted={JS.dispatch("chess:show-modal")}
      >
        <p>Play as:</p>
        <.button phx-click="new-game" phx-value-playing_as="black">Black</.button>
        <.button phx-click="new-game" phx-value-playing_as="white">White</.button>
      </dialog>
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

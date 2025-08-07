defmodule ChessWeb.GameLive.New do
  use ChessWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      Play as:
      <div>
        <.button navigate={~p"/games/play?playing_as=black"}>Black</.button>
        <.button navigate={~p"/games/play?playing_as=white"}>White</.button>
      </div>
    </div>
    """
  end
end

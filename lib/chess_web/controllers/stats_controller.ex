defmodule ChessWeb.StatsController do
  alias Chess.Repo
  alias Chess.Game
  use ChessWeb, :controller

  def index(conn, _params) do
    total_games =
      Game
      |> Repo.aggregate(:count)

    active_games =
      Registry.select(Chess.Registry, [{{:"$1", :_, :_}, [], [{{:"$1"}}]}])
      |> Enum.uniq_by(fn {uuid} -> uuid end)
      |> Enum.map(fn {uuid} -> uuid end)
      |> Enum.count()

    spectators =
      Registry.select(Chess.Registry, [{{:_, :_, :spectate}, [], [{{true}}]}])
      |> Enum.count()

    render(conn, :index,
      total_games: total_games,
      active_games: active_games,
      spectators: spectators
    )
  end
end

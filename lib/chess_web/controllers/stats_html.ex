defmodule ChessWeb.StatsHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `stats_html` directory for all templates available.
  """
  use ChessWeb, :html

  embed_templates "stats_html/*"
end

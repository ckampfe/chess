defmodule Chess.Repo do
  use Ecto.Repo,
    otp_app: :chess,
    adapter: Ecto.Adapters.SQLite3
end

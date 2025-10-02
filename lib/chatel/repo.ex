defmodule Chatel.Repo do
  use Ecto.Repo,
    otp_app: :chatel,
    adapter: Ecto.Adapters.Postgres
end

defmodule ChatelWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :chatel,
    pubsub_server: Chatel.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def fetch(_topic, presences) do
    presences
    |> Enum.map(fn {key, %{metas: [meta | _metas]}} ->
      user = Chatel.Accounts.get_user!(meta.id)
      enriched_payload = %{metas: Map.get(presences, key, %{})[:metas], user: user}

      {key, enriched_payload}
    end)
    |> Map.new()
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{id: user_id, user: presence.user, metas: Map.fetch!(presences, user_id)}
      msg = {__MODULE__, {:join, user_data}}
      Phoenix.PubSub.local_broadcast(Chatel.PubSub, "proxy:#{topic}", msg)
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{id: user_id, user: presence.user, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}
      Phoenix.PubSub.local_broadcast(Chatel.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end

  def list_online_users(),
    do: list("online_users") |> Enum.map(fn {_id, presence} -> presence end)
end

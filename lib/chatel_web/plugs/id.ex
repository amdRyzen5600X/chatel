defmodule ChatelWeb.Plugs.Id do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{params: %{"id" => id}} = conn, _default) do
    assign(conn, :id, id)
  end

  def call(conn, default) do
    assign(conn, :id, default)
  end
end

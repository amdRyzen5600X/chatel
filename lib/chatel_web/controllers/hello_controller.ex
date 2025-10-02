defmodule ChatelWeb.HelloController do
  use ChatelWeb, :controller

  def index(conn, %{"name" => name}) do
    IO.puts("HelloController.index")
    IO.inspect(conn)
    render(conn, :index, name: name)
  end

  def hello(conn, _params) do
    IO.puts("HelloController.hello")
    render(conn, :hello)
  end
end

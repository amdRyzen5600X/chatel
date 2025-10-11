defmodule ChatelWeb.HelloJSON do
  use ChatelWeb, :controller

  def hello(%{conn: %Plug.Conn{body_params: params}}) do
    if params["name"] do
      %{message: "Hello #{params["name"]}"}
    else
      %{message: "Hello World"}
    end
  end
end

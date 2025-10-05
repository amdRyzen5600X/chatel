defmodule ChatelWeb.UserChangeUsernameLive do
  use ChatelWeb, :live_view

  alias Chatel.Accounts

  def mount(%{"token" => token}, _session, socket) do
    IO.inspect(socket)
    IO.puts("-----------------------------")
    IO.inspect(_session)

    socket =
      case Accounts.update_user_username(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Username changed successfully.")

        :error ->
          put_flash(socket, :error, "Username change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end
end

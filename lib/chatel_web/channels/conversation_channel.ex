defmodule ChatelWeb.ConversationChannel do
  use Phoenix.Channel

  def join("conversation:lobby", _payload, socket) do
    {:ok, socket}
  end

  def handle_in(event, payload, socket) do
    broadcast(socket, event, payload)
    {:noreply, socket}
  end

end

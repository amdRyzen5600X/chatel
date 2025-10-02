defmodule ChatelWeb.ConversationChannel do
  use ChatelWeb, :channel

  @impl true
  def join("conversation:lobby", _payload, socket) do
    {:ok, socket}
  end

  @impl true
  def join("conversation:" <> _, _, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (conversation:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  intercept ["user_joined"]

  @impl true
  def handle_out("user_joined", msg, socket) do
    push(socket, "user_joined", msg)
    {:noreply, socket}
  end
end

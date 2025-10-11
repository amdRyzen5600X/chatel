defmodule ChatelWeb.ChatList do
  alias ChatelWeb.CoreComponents
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <ul
      id="chat-list-component"
      class="divide-y border-y border-gray-200 dark:border-gray-700 divide-gray-200 dark:divide-gray-700"
    >
      <%= for chat <- @chats do %>
        <CoreComponents.chat chat={chat} />
      <% end %>
    </ul>
    """
  end

  def handle_event("chat_created", _params, socket) do
    {:noreply, socket}
  end
end

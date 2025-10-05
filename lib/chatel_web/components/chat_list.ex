defmodule ChatelWeb.ChatList do
  alias ChatelWeb.CoreComponents
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <ul
      id="chat-list-component"
      class="divide-y border-y border-gray-200 dark:border-gray-700 divide-gray-200 dark:divide-gray-700"
    >
      <%= for user <- @users do %>
        <CoreComponents.user chat={user} />
      <% end %>

      <%= for group_chat <- @group_chats do %>
        <CoreComponents.group_chat chat={group_chat} />
      <% end %>
    </ul>
    """
  end

  def handle_event("chat_created", _params, socket) do
    {:noreply, socket}
  end
end

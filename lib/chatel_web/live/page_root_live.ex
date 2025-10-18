defmodule ChatelWeb.PageRootLive do
  alias ChatelWeb.Presence
  use ChatelWeb, :live_view_chat

  @online_users_topic "online_users"

  def render(assigns) do
    ~H"""
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    updates_topic = "user_updates:#{current_user.id}"
    ChatelWeb.Endpoint.subscribe(updates_topic)

    Presence.track(self(), @online_users_topic, current_user.id, %{id: current_user.id})
    Phoenix.PubSub.subscribe(Chatel.PubSub, @online_users_topic)

    chats = Chatel.Chat.list_all_conversations(current_user.id)

    socket =
      socket
      |> assign(:chat_form, to_form(%{}))
      |> assign(:online_users, ChatelWeb.Presence.list(@online_users_topic))
      |> assign(:chats, chats)
      |> assign(:current_chat, nil)
      |> assign(:current_user, current_user)
      |> assign(:message_form, %{"message" => ""})
      |> assign(:other_topic, updates_topic)
      |> assign(:message_text, "")
      |> assign(:parent, self())

    {:ok, socket}
  end

  def handle_info(:chat_created, socket) do
    chats = Chatel.Chat.list_all_conversations(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(:chats, chats)
      |> push_navigate(to: ~p"/")

    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end

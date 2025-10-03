defmodule ChatelWeb.PageRootLive do
  alias ChatelWeb.CreateChatModal
  alias ChatelWeb.Presence
  use ChatelWeb, :live_view_chat

  @other_chat_topic "chat:other"
  @online_users_topic "online_users"

  def render(assigns) do
    ~H"""
    """
  end

  def mount(_params, _session, socket) do
    ChatelWeb.Endpoint.subscribe(@other_chat_topic)
    current_user = socket.assigns.current_user

    Presence.track(self(), @online_users_topic, current_user.id, %{id: current_user.id})
    Phoenix.PubSub.subscribe(Chatel.PubSub, @online_users_topic)

    {users, group_chats} = Chatel.Chat.list_all_chats(current_user.id)

    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:chat_form, to_form(%{}))
      |> assign(:online_users, ChatelWeb.Presence.list(@online_users_topic))
      |> assign(:users, users)
      |> assign(:group_chats, group_chats)
      |> assign(:current_chat, nil)
      |> assign(:current_user, current_user)
      |> assign(:message_form, %{"message" => ""})
      |> assign(:other_topic, @other_chat_topic)
      |> assign(:message_text, "")
      |> assign(:parent, self())

    {:ok, socket}
  end

  def handle_info(:chat_created, socket) do
    {users, group_chats} = Chatel.Chat.list_all_chats(socket.assigns.current_user.id)
    socket =
      socket
      |> assign(:users, users)
      |> assign(:group_chats, group_chats)
    {:noreply, socket}
  end
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end

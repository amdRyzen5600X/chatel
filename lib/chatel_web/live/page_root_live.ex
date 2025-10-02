defmodule ChatelWeb.PageRootLive do
  alias ChatelWeb.Presence
  alias Chatel.Chat
  use ChatelWeb, :live_view_chat

  alias Chatel.Accounts

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
      |> assign(:online_users, ChatelWeb.Presence.list(@online_users_topic))
      |> assign(:users, users)
      |> assign(:group_chats, group_chats)
      |> assign(:current_chat, nil)
      |> assign(:current_user, current_user)
      |> assign(:message_form, %{"message" => ""})
      |> assign(:other_topic, @other_chat_topic)
      |> assign(:message_text, "")

    {:ok, socket}
  end
end

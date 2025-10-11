defmodule ChatelWeb.GroupChatLive do
  alias Chatel.Conversation.GroupChat
  use ChatelWeb, :live_view_chat

  @other_chat_topic "chat:other"

  def render(assigns) do
    ~H"""
    <div id="messages" class="overflow-y-auto p-4 min-h-0" phx-hook="ScrollToBottom">
      <%= if @current_chat do %>
        <div class="flex flex-col space-y-4">
          <%= for message <- @messages do %>
            <.live_component
              module={ChatelWeb.MessageComponent}
              id={message.id}
              message={message}
              current_user={@current_user}
              group_chat?={@group_chat?}
            />
          <% end %>
        </div>
      <% end %>
    </div>

    <.message_input
      current_chat={@current_chat}
      message_text={@message_text}
      message_form={@message_form}
    />
    """
  end

  def mount(%{"chatname" => chatname}, _session, socket) do
    ChatelWeb.Endpoint.subscribe(@other_chat_topic)
    current_user = socket.assigns.current_user

    chats = Chatel.Chat.list_all_chats(current_user.id)

    current_chat =
      chats
      |> Enum.find(fn group_chat -> group_chat.chat_name == chatname end)

    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:group_chat?, true)
      |> assign(:chat_form, to_form(%{}))
      |> assign(:parent, self())
      |> assign(:chats, chats)
      |> assign(:current_chat, current_chat)
      |> assign(:current_user, current_user)
      |> assign(:online_users, nil)
      |> assign(:message_text, "")
      |> assign(:other_topic, @other_chat_topic)
      |> assign(:message_form, %{"message" => ""})

    socket =
      if not is_nil(current_chat) and not is_nil(current_user) do
        topic = "chat:#{current_chat.chat_name}"
        ChatelWeb.Endpoint.subscribe(topic)

        messages = Chatel.Chat.list_group_messages(current_chat.id)

        socket
        |> assign(:messages, messages)
        |> assign(:topic, topic)
      else
        socket
        |> assign(:messages, [])
      end

    {:ok, socket}
  end

  def handle_event("send_message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    %{current_user: sender, current_chat: group_chat, topic: topic} = socket.assigns

    with {:ok, message} <- Chatel.Chat.create_group_message(sender.id, group_chat.id, message) do
      ChatelWeb.Endpoint.broadcast(topic, "new_message", %{message: message})
      ChatelWeb.Endpoint.broadcast(@other_chat_topic, "new_message", %{message: message})

      {:noreply,
       socket
       |> assign(:message_text, "")}
    end
  end

  def handle_event("update_text", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message_text, message)}
  end

  def handle_info(
        %{event: "new_message", payload: %{message: message}, topic: @other_chat_topic},
        socket
      ) do
    group_chat_id = message.group_chat_id

    group_chats =
      socket.assigns.group_chats
      |> Enum.map(fn group_chat ->
        if group_chat.id == group_chat_id do
          group_chat
          |> Map.put(:last_message, message)
        else
          group_chat
        end
      end)

    {:noreply,
     socket
     |> assign(:group_chats, group_chats)}
  end

  def handle_info(%{event: "new_message", payload: %{message: message}, topic: _}, socket) do
    {:noreply,
     socket
     |> update(:messages, fn messages -> messages ++ [message] end)}
  end
end

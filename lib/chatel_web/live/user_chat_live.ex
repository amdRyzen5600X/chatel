defmodule ChatelWeb.UserChatLive do
  use ChatelWeb, :live_view_chat

  @other_chat_topic "chat:other"
  @online_users_topic "online_users"

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
              show_modal={@modal_states[message.id]}
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

  def mount(%{"username" => username}, _session, socket) do
    ChatelWeb.Endpoint.subscribe(@other_chat_topic)
    current_user = socket.assigns.current_user

    ChatelWeb.Presence.track(self(), @online_users_topic, current_user.id, %{id: current_user.id})
    Phoenix.PubSub.subscribe(Chatel.PubSub, @online_users_topic)

    {users, group_chats} = Chatel.Chat.list_all_chats(current_user.id)

    current_chat =
      users
      |> Enum.find(fn user -> user.username == username end)

    socket =
      socket
      |> assign(:group_chat?, false)
      |> assign(:show_modal, false)
      |> assign(:chat_form, to_form(%{}))
      |> assign(:parent, self())
      |> assign(:online_users, ChatelWeb.Presence.list(@online_users_topic))
      |> assign(:users, users)
      |> assign(:group_chats, group_chats)
      |> assign(:current_chat, current_chat)
      |> assign(:current_user, current_user)
      |> assign(:message_text, "")
      |> assign(:other_topic, @other_chat_topic)
      |> assign(:message_form, %{"message" => ""})
      |> assign(:modal_states, %{})

    socket =
      if not is_nil(current_chat) and not is_nil(current_user) do
        topic = build_topic(current_user, current_chat)
        ChatelWeb.Endpoint.subscribe(topic)

        messages = Chatel.Chat.list_messages(current_user.id, current_chat.id)

        socket
        |> assign(:messages, messages)
        |> assign(:topic, topic)
      else
        socket
        |> assign(:messages, [])
      end

    {:ok, socket}
  end

  defp build_topic(user1, user2) do
    [user1.username, user2.username]
    |> Enum.sort()
    |> Enum.join(":")
    |> then(&"chat:#{&1}")
  end

  def handle_event("send_message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    %{current_user: sender, current_chat: recipient, topic: topic} = socket.assigns

    with {:ok, message} <- Chatel.Chat.create_message(sender.id, recipient.id, message) do
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

  def handle_info({:show_modal, message_id}, socket) do
    {:noreply,
     assign(socket, :modal_states, Map.put(socket.assigns.modal_states, message_id, true))}
  end

  def handle_info({:hide_modal, message_id}, socket) do
    {:noreply,
     assign(socket, :modal_states, Map.put(socket.assigns.modal_states, message_id, false))}
  end

  def handle_info(
        %{event: "new_message", payload: %{message: message}, topic: @other_chat_topic},
        socket
      ) do
    recipient_id = message.recipient_user_id
    sender_id = message.sender_user_id

    users =
      socket.assigns.users
      |> Enum.map(fn user ->
        if user.id == recipient_id or user.id == sender_id do
          user
          |> Map.put(:last_message, message)
        else
          user
        end
      end)

    {:noreply,
     socket
     |> assign(:users, users)}
  end

  def handle_info(%{event: "new_message", payload: %{message: message}, topic: _}, socket) do
    {:noreply,
     socket
     |> update(:messages, fn messages -> messages ++ [message] end)}
  end

  def handle_info(%{event: "presence_diff", topic: @online_users_topic}, socket) do
    IO.inspect(socket)
    {:noreply, assign(socket, :online_users, ChatelWeb.Presence.list(@online_users_topic))}
  end
end

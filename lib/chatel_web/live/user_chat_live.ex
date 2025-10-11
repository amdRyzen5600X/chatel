defmodule ChatelWeb.UserChatLive do
  alias Chatel.Chat
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
              current_chat={@current_chat}
              group_chat?={@group_chat?}
              show_modal={@modal_states[message.id]}
              parrent={self()}
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

    chats = Chatel.Chat.list_all_chats(current_user.id)

    current_chat =
      chats
      |> Enum.find(fn chat -> chat.chat_name == username end)

    socket =
      socket
      |> assign(:group_chat?, current_chat.is_group_chat)
      |> assign(:show_modal, false)
      |> assign(:chat_form, to_form(%{}))
      |> assign(:parent, self())
      |> assign(:online_users, ChatelWeb.Presence.list(@online_users_topic))
      |> assign(:chats, chats)
      |> assign(:current_chat, current_chat)
      |> assign(:current_user, current_user)
      |> assign(:message_text, "")
      |> assign(:other_topic, @other_chat_topic)
      |> assign(:message_form, %{"message" => ""})
      |> assign(:modal_states, %{})

    socket =
      if not is_nil(current_chat) and not is_nil(current_user) do
        topic =
          if current_chat.is_group_chat do
            "chat:#{current_chat.chat_name}"
          else
            build_topic(current_user, current_chat)
          end

        ChatelWeb.Endpoint.subscribe(topic)

        messages =
          if current_chat.is_group_chat do
            Chatel.Chat.list_group_messages(current_chat.id)
          else
            Chatel.Chat.list_messages(current_user.id, current_chat.id)
          end

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
    user1name =
      case Map.fetch(user1, :username) do
        {:ok, username} ->
          username

        :error ->
          user1.chat_name
      end

    user2name =
      case Map.fetch(user2, :username) do
        {:ok, username} ->
          username

        :error ->
          user2.chat_name
      end

    [user1name, user2name]
    |> Enum.sort()
    |> Enum.join(":")
    |> then(&"chat:#{&1}")
  end

  def handle_event("send_message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    %{
      current_user: sender,
      current_chat: current_chat,
      topic: topic,
      group_chat?: group_chat?
    } = socket.assigns

    if group_chat? do
      with {:ok, message} <- Chatel.Chat.create_group_message(sender.id, current_chat.id, message) do
        ChatelWeb.Endpoint.broadcast(topic, "new_message", %{message: message})
        ChatelWeb.Endpoint.broadcast(@other_chat_topic, "new_message", %{message: message})

        {:noreply,
         socket
         |> assign(:message_text, "")}
      end
    else
      with {:ok, message} <- Chatel.Chat.create_message(sender.id, current_chat.id, message) do
        ChatelWeb.Endpoint.broadcast(topic, "new_message", %{message: message})
        ChatelWeb.Endpoint.broadcast(@other_chat_topic, "new_message", %{message: message})

        {:noreply,
         socket
         |> assign(:message_text, "")}
      end
    end
  end

  def handle_event("update_text", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message_text, message)}
  end

  def handle_info({:message_deleted, message_id, group_chat?}, socket) do
    ChatelWeb.Endpoint.broadcast(@other_chat_topic, "message_deleted", {message_id, group_chat?})

    {:noreply, socket}
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
        %{event: "message_deleted", payload: {message_id, group_chat?}, topic: @other_chat_topic},
        socket
      ) do
    chats =
      socket.assigns.chats
      |> Enum.map(fn chat ->
        if chat.last_message.id == message_id and chat.is_group_chat == group_chat? do
          if group_chat? do
            Map.put(chat, :last_message, Chat.last_group_message(chat.id))
          else
            Map.put(
              chat,
              :last_message,
              Chat.last_message(chat.id, socket.assigns.current_user.id)
            )
          end
        else
          chat
        end
      end)
      |> Enum.sort_by(& &1.last_message.inserted_at, :desc)

    messages =
      socket.assigns.messages
      |> Enum.filter(fn msg ->
        !(socket.assigns.group_chat? == group_chat? and
            msg.id == message_id)
      end)

    socket =
      socket
      |> assign(:chats, chats)
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_info(
        %{event: "new_message", payload: %{message: message}, topic: @other_chat_topic},
        socket
      ) do
    {recipient_id, group_chat?} =
      case Map.fetch(message, :recipient_user_id) do
        {:ok, recipient_user_id} ->
          {recipient_user_id, false}

        :error ->
          {message.group_chat_id, true}
      end

    sender_id = message.sender_user_id

    chats =
      socket.assigns.chats
      |> Enum.map(fn chat ->
        if chat.id == recipient_id and chat.is_group_chat == group_chat? and chat.is_group_chat do
          Map.put(chat, :last_message, message)
        else
          if (chat.id == recipient_id or chat.id == sender_id) and
               chat.is_group_chat == group_chat? and !chat.is_group_chat do
            Map.put(chat, :last_message, message)
          else
            chat
          end
        end
      end)

    {:noreply,
     socket
     |> assign(
       :chats,
       chats
       |> Enum.sort_by(& &1.last_message.inserted_at, :desc)
     )}
  end

  def handle_info(%{event: "new_message", payload: %{message: message}, topic: _}, socket) do
    {:noreply,
     socket
     |> update(:messages, fn messages -> messages ++ [message] end)}
  end

  def handle_info(%{event: "presence_diff", topic: @online_users_topic}, socket) do
    {:noreply, assign(socket, :online_users, ChatelWeb.Presence.list(@online_users_topic))}
  end
end

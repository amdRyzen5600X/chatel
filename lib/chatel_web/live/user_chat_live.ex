defmodule ChatelWeb.UserChatLive do
  alias Chatel.Chat
  use ChatelWeb, :live_view_chat

  @online_users_topic "online_users"

  def render(assigns) do
    ~H"""
    <div id="messages" class="overflow-y-auto p-4 min-h-0" phx-hook="ScrollToBottom">
      <%= if @current_chat do %>
        <%= if @cursor do %>
          <div id="infinite-scroll-trigger" phx-hook="InfiniteScroll">
            Loading more...
          </div>
        <% end %>

        <div class="flex flex-col space-y-4">
          <%= for message <- @messages do %>
            <.live_component
              module={ChatelWeb.MessageComponent}
              id={message.id}
              message={message}
              current_user={@current_user}
              current_chat={@current_chat}
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

  def mount(%{"conversation_id" => conversation_id}, _session, socket) do
    current_user = socket.assigns.current_user
    updates_topic = "user_updates:#{current_user.id}"
    ChatelWeb.Endpoint.subscribe(updates_topic)

    ChatelWeb.Presence.track(self(), @online_users_topic, current_user.id, %{id: current_user.id})
    Phoenix.PubSub.subscribe(Chatel.PubSub, @online_users_topic)

    chats = Chatel.Chat.list_all_conversations(current_user.id)

    current_chat =
      chats
      |> Enum.find(fn chat -> Integer.to_string(chat.id) == conversation_id end)

    socket =
      socket
      |> assign(:chat_form, to_form(%{}))
      |> assign(:parent, self())
      |> assign(:online_users, ChatelWeb.Presence.list(@online_users_topic))
      |> assign(:chats, chats)
      |> assign(:current_chat, current_chat)
      |> assign(:current_user, current_user)
      |> assign(:message_text, "")
      |> assign(:other_topic, updates_topic)
      |> assign(:message_form, %{"message" => ""})

    socket =
      if not is_nil(current_chat) and not is_nil(current_user) do
        topic =
          "chat:#{current_chat.id}"

        ChatelWeb.Endpoint.subscribe(topic)

        messages =
          Chatel.Chat.list_messages(current_chat.id)

        cursor = if length(messages) > 0, do: hd(messages).inserted_at, else: nil

        socket
        |> assign(:messages, messages)
        |> assign(:topic, topic)
        |> assign(:cursor, cursor)
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
    %{
      current_user: sender,
      current_chat: current_chat,
      topic: topic
    } = socket.assigns

    with {:ok, message} <- Chatel.Chat.create_message(sender.id, current_chat.id, message) do
      ChatelWeb.Endpoint.broadcast(topic, "new_message", %{message: message})

      update_message = %{
        conversation_id: message.conversation_id,
        text: String.slice(message.text, 0, 30) <> "...",
        inserted_at: message.inserted_at
      }

      current_chat.participants
      |> Enum.map(fn user ->
        ChatelWeb.Endpoint.broadcast("user_updates:#{user.id}", "new_message", %{
          message: update_message
        })
      end)

      {:noreply,
       socket
       |> assign(:message_text, "")}
    end
  end

  def handle_event("update_text", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message_text, message)}
  end

  def handle_event("load_more", _, socket) do
    %{
      cursor: cursor,
      current_chat: chat,
      messages: old_messages
    } =
      socket.assigns

    if is_nil(cursor) do
      {:noreply, socket}
    else
      more_messages =
        Chat.list_messages(chat.id, cursor)

      all_messages = more_messages ++ old_messages

      new_cursor = if length(more_messages) > 0, do: hd(more_messages).inserted_at, else: nil

      {:noreply,
       socket
       |> assign(:messages, all_messages)
       |> assign(:cursor, new_cursor)}
    end
  end

  def handle_info({:message_deleted, message_id}, socket) do
    current_chat = socket.assigns.current_chat

    current_chat.users
    |> Enum.map(fn user ->
      ChatelWeb.Endpoint.broadcast(
        "user_updates:#{user.id}",
        "message_deleted",
        {message_id}
      )
    end)

    {:noreply, socket}
  end

  def handle_info(
        %{
          event: "message_deleted",
          payload: {message_id},
          topic: "user_updates:" <> _user_id
        },
        socket
      ) do
    chats =
      socket.assigns.chats
      |> Enum.map(fn chat ->
        if chat.last_message.id == message_id do
          Map.put(chat, :last_message, Chat.last_message(chat.id))
        else
          chat
        end
      end)
      |> Enum.sort_by(& &1.last_message.inserted_at, :desc)

    messages =
      socket.assigns.messages
      |> Enum.filter(fn msg ->
        !(msg.id == message_id)
      end)

    socket =
      socket
      |> assign(:chats, chats)
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_info(
        %{event: "new_message", payload: %{message: message}, topic: "user_updates:" <> _user_id},
        socket
      ) do
    conversation_id = message.conversation_id

    chats =
      socket.assigns.chats
      |> Enum.map(fn chat ->
        if chat.id == conversation_id do
          Map.put(chat, :last_message, message)
        else
          chat
        end
      end)
      |> Enum.sort_by(& &1.last_message.inserted_at, :desc)

    {:noreply, assign(socket, :chats, chats)}
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

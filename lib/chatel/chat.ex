defmodule Chatel.Chat do
  import Ecto.Query
  alias Chatel.Conversation.Message
  alias Chatel.Conversation.ChatMessage
  alias Chatel.Repo

  def list_group_messages(group_chat_id) do
    Repo.all(ChatMessage)
    |> Repo.preload(:sender_user)
    |> Enum.filter(fn msg -> msg.group_chat_id == group_chat_id end)
  end

  def list_messages(user1_id, user2_id) do
    Repo.all(Message)
    |> Repo.preload(:sender_user)
    |> Enum.filter(fn msg ->
      msg.sender_user_id == user1_id || msg.recipient_user_id == user1_id
    end)
    |> Enum.filter(fn msg ->
      msg.sender_user_id == user2_id || msg.recipient_user_id == user2_id
    end)
  end

  def last_group_message(group_chat_id) do
    query =
      from m in ChatMessage,
        where: m.group_chat_id == ^group_chat_id,
        order_by: [desc: m.inserted_at],
        limit: 1,
        select: m

    Repo.one(query)
  end

  def last_message(user1_id, user2_id) do
    query =
      from m in Message,
        where:
          (m.sender_user_id == ^user1_id and m.recipient_user_id == ^user2_id) or
            (m.sender_user_id == ^user2_id and m.recipient_user_id == ^user1_id),
        order_by: [desc: m.inserted_at],
        limit: 1,
        select: m

    Repo.one(query)
  end

  def create_message(sender_id, recipient_id, text) do
    %Chatel.Conversation.Message{}
    |> Chatel.Conversation.Message.changeset(%{
      sender_user_id: sender_id,
      recipient_user_id: recipient_id,
      text: text
    })
    |> Repo.insert()
  end

  def create_group_message(sender_id, group_chat_id, text) do
    %Chatel.Conversation.ChatMessage{}
    |> Chatel.Conversation.ChatMessage.changeset(%{
      sender_user_id: sender_id,
      group_chat_id: group_chat_id,
      text: text
    })
    |> Repo.insert()
  end

  def list_all_chats(current_user_id) do
    users =
      Chatel.Accounts.list_users()
      |> Enum.filter(fn user -> user.id != current_user_id end)
      |> Enum.map(fn user ->
        %{
          id: user.id,
          display_name: user.username,
          chat_name: user.username,
          last_message: Chatel.Chat.last_message(user.id, current_user_id),
          is_group_chat: false,
          users: []
        }
      end)

    group_chats =
      Chatel.Conversation.GroupChat.list_group_chats(current_user_id)
      |> Enum.map(fn group_chat ->
        %{
          id: group_chat.id,
          display_name: group_chat.display_name,
          chat_name: group_chat.display_name,
          last_message: Chatel.Chat.last_group_message(group_chat.id),
          is_group_chat: true,
          users: group_chat.users
        }
      end)

    List.flatten([users | group_chats])
  end

  def create_group_chat(display_name, chat_name, user_ids, owner_id) do
    %Chatel.Conversation.GroupChat{}
    |> Chatel.Conversation.GroupChat.changeset(%{
      display_name: display_name,
      chat_name: chat_name,
      owner_id: owner_id,
      user_ids: user_ids
    })
    |> Repo.insert()
  end
end

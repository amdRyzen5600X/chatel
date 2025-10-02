defmodule Chatel.Chat do
  import Ecto.Query
  alias Chatel.Conversation.Message
  alias Chatel.Conversation.ChatMessage
  alias Chatel.Repo

  def list_group_messages(group_chat_id) do
    query =
      from m in ChatMessage,
        where: m.group_chat_id == ^group_chat_id,
        order_by: [asc: m.inserted_at],
        select: m

    Repo.all(query)
  end

  def list_messages(user1_id, user2_id) do
    query =
      from m in Message,
        where:
          (m.sender_user_id == ^user1_id and m.recipient_user_id == ^user2_id) or
            (m.sender_user_id == ^user2_id and m.recipient_user_id == ^user1_id),
        order_by: [asc: m.inserted_at],
        select: m

    Repo.all(query)
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
        %{user | last_message: Chatel.Chat.last_message(user.id, current_user_id)}
      end)

    group_chats =
      Chatel.Conversation.GroupChat.list_group_chats(current_user_id)
      |> Enum.map(fn group_chat ->
        %{group_chat | last_message: Chatel.Chat.last_group_message(group_chat.id)}
      end)
    {users, group_chats}
  end
end

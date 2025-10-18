defmodule Chatel.Chat do
  import Ecto.Query
  alias Chatel.Conversation
  alias Chatel.Conversation.Conversation
  alias Chatel.Conversation.Message
  alias Chatel.Repo

  @page_size 100
  @conversation_type_group "group"
  @conversation_type_dm "direct"

  def list_messages(conversation_id, cursor_timestamp \\ nil) do
    base_query =
      from m in Message,
        where: m.conversation_id == ^conversation_id

    paginated_query =
      if cursor_timestamp do
        from q in base_query, where: q.inserted_at < ^cursor_timestamp
      else
        base_query
      end

    from(q in paginated_query,
      order_by: [desc: q.inserted_at, desc: q.id],
      limit: @page_size,
      preload: [:sender_user]
    )
    |> Repo.all()
    |> Enum.reverse()
    |> Enum.map(fn msg ->
      Map.put(msg, :text, Chatel.Vault.decrypt!(msg.text))
    end)
  end

  def last_message(conversation_id) do
    query =
      from m in Message,
        where: m.conversation_id == ^conversation_id,
        order_by: [desc: m.inserted_at],
        limit: 1,
        select: m

    Repo.one(query)
  end

  def create_message(sender_id, conversation_id, text) do
    with {:ok, enc_text} <- Chatel.Vault.encrypt(text) do
      %Chatel.Conversation.Message{}
      |> Chatel.Conversation.Message.changeset(%{
        sender_id: sender_id,
        conversation_id: conversation_id,
        text: enc_text
      })
      |> Repo.insert()
    end
  end

  def list_chats_with_last_message(current_user_id) do
    query =
      from gc in Chatel.Conversation.Conversation,
        join: gcu in "conversation_participants",
        on: gcu.conversation_id == gc.id and gcu.user_id == ^current_user_id,
        left_lateral_join:
          lm in fragment(
            "select id, text, sender_id, inserted_at, updated_at, conversation_id from messages where conversation_id = ? order by inserted_at desc limit 1",
            gc.id
          ),
        on: lm.conversation_id == gc.id,
        preload: [:participants],
        select:
          merge(gc, %{last_message: %{id: lm.id, text: lm.text, inserted_at: lm.inserted_at}})

    Repo.all(query)
  end

  def list_all_conversations(current_user_id) do
    conversations = list_chats_with_last_message(current_user_id)

    conversations
    |> Enum.sort_by(& &1.last_message.inserted_at, :desc)
    |> Enum.map(fn chat ->
      {chat_name, group_chat?, users, owner_id} =
        if is_nil(chat.group_name) do
          other_user =
            chat.participants
            |> Enum.find(fn participant ->
              participant.id != current_user_id
            end)

          {other_user.username, false, chat.participants, nil}
        else
          {chat.group_name, true, chat.participants, chat.owner_id}
        end

      last_message =
        chat.last_message
        |> Map.put(:text, Chatel.Vault.decrypt!(Chatel.Vault.decrypt!(chat.last_message.text)))

      %{
        chat_name: chat_name,
        id: chat.id,
        display_name: chat_name,
        last_message: last_message,
        group_chat?: group_chat?,
        users: users,
        owner_id: owner_id
      }
    end)
  end

  def create_conversation(type, group_name, user_ids, owner_id) do
    participants =
      Repo.all(from u in Chatel.Accounts.User, where: u.id in ^user_ids)

    %Conversation{}
    |> Conversation.changeset(%{
      type: type,
      group_name: group_name,
      owner_id: owner_id,
      participants: participants
    })
    |> Repo.insert()
  end

  def delete_message(message_id) do
    %Chatel.Conversation.Message{id: message_id}
    |> Repo.delete()
  end

  def find_or_create_conversation(current_user, participant_ids, group_name \\ nil) do
    all_participant_ids = [current_user.id | participant_ids] |> Enum.uniq()
    group_chat? = not (is_nil(group_name) or String.trim(group_name) == "")
    dm? = not group_chat? and length(all_participant_ids) == 2

    cond do
      group_chat? ->
        create_conversation(
          @conversation_type_group,
          group_name,
          all_participant_ids,
          current_user.id
        )

      dm? ->
        find_existing_dm(all_participant_ids)
        |> case do
          nil -> create_conversation(@conversation_type_dm, nil, all_participant_ids, nil)
          existing_conversation -> {:ok, existing_conversation}
        end

      true ->
        {:error, :invalid_parameters}
    end
  end

  def find_existing_dm(participant_ids) do
    query =
      from c in Conversation,
        where: c.type == ^@conversation_type_dm,
        join: p in "conversation_participants",
        on: p.conversation_id == c.id,
        group_by: c.id,
        having:
          count(p.user_id) == 2 and
            fragment("bool_and(?)", p.user_id in ^participant_ids),
        limit: 1

    Repo.one(query)
  end
end

defmodule Chatel.ConversationTest do
  use Chatel.DataCase

  alias Chatel.Conversation

  describe "messages" do
    alias Chatel.Conversation.Message

    import Chatel.ConversationFixtures

    @invalid_attrs %{text: nil, created_at: nil, updated_at: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Conversation.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Conversation.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = %{text: "some text", created_at: ~U[2025-09-25 18:17:00Z], updated_at: ~U[2025-09-25 18:17:00Z]}

      assert {:ok, %Message{} = message} = Conversation.create_message(valid_attrs)
      assert message.text == "some text"
      assert message.created_at == ~U[2025-09-25 18:17:00Z]
      assert message.updated_at == ~U[2025-09-25 18:17:00Z]
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversation.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      update_attrs = %{text: "some updated text", created_at: ~U[2025-09-26 18:17:00Z], updated_at: ~U[2025-09-26 18:17:00Z]}

      assert {:ok, %Message{} = message} = Conversation.update_message(message, update_attrs)
      assert message.text == "some updated text"
      assert message.created_at == ~U[2025-09-26 18:17:00Z]
      assert message.updated_at == ~U[2025-09-26 18:17:00Z]
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Conversation.update_message(message, @invalid_attrs)
      assert message == Conversation.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Conversation.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Conversation.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Conversation.change_message(message)
    end
  end
end

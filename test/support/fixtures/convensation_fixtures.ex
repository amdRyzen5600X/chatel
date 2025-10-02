defmodule Chatel.ConversationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chatel.Conversation` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        created_at: ~U[2025-09-25 18:17:00Z],
        text: "some text",
        updated_at: ~U[2025-09-25 18:17:00Z]
      })
      |> Chatel.Conversation.create_message()

    message
  end
end

defmodule ChatelWeb.UserSearchComponent do
  use ChatelWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h3 class="text-xl font-bold mb-4">Find user to chat with</h3>

      <.form phx-change="search" phx-debounce="300" phx-target={@myself}>
        <.input
          name="query"
          type="text"
          placeholder="Search by username..."
          value={@query}
          autocomplete="off"
          autofocus
        />
      </.form>

      <div class="mt-4 space-y-2 min-h-[10rem]">
        <%= if @query != "" do %>
          <%= for user <- @results do %>
            <div
              phx-click="start_dm"
              phx-value-id={user.id}
              phx-target={@myself}
              class="flex items-center justify-between p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
            >
              <span class="font-semibold">{user.username}</span>
              <span class="text-sm text-gray-500">Start Chat</span>
            </div>
          <% end %>

          <%= if @results == [] do %>
            <p class="text-gray-500">No users found matching "{@query}".</p>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"query" => query}, socket) do
    results =
      if String.trim(query) == "" do
        []
      else
        Chatel.Accounts.search_users_by_username(query, socket.assigns.current_user)
      end

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:results, results)}
  end

  def handle_event("start_dm", %{"id" => user_id}, socket) do
    participant_id = String.to_integer(user_id)

    case Chatel.Chat.find_or_create_conversation(socket.assigns.current_user, [participant_id]) do
      {:ok, conversation} ->
        {:noreply, push_navigate(socket, to: ~p"/#{conversation.id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not start conversation.")}
    end
  end
end

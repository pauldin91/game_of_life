defmodule GameOfLifeWeb.CustomComponents do
  use Phoenix.Component

  attr :entry, :any, required: true
  @spec render_prop_input(map()) :: Phoenix.LiveView.Rendered.t()
  def render_prop_input(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 w-48">
      <div class="flex justify-between text-sm text-gray-500">
        <span>{@entry.name}</span>
        <span>{@entry.value || @entry.default}</span>
      </div>
      <form phx-change={@entry.name}>
        <input
          type="range"
          name={@entry.name}
          value={@entry.value || @entry.default}
          min={@entry.min}
          max={@entry.max}
          step={@entry.step}
          class="range range-sm"
        />
      </form>
    </div>
    """
  end

  attr :matrix, :any, required: true
  attr :toggleable, :boolean, default: false
  attr :dropzone, :boolean, default: false

  def board(assigns) do
    ~H"""
    <table class={if @dropzone == 0, do: "board-table-dropzone", else: "board-table"}>
      <thead>
        <tr>
          <th class="board-cell-label"></th>
          <th :for={i <- 1..Enum.count(@matrix)} class="board-cell-label">{i}</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={{row, i} <- Enum.with_index(@matrix, 1)}>
          <th class="board-cell-label">{i}</th>
          <td
            :for={{cell, j} <- Enum.with_index(row, 1)}
            class={"board-cell #{if cell == 0, do: "board-cell-light", else: "board-cell-dark"}"}
            phx-click={if @toggleable, do: "toggle"}
            phx-value-i={i - 1}
            phx-value-j={j - 1}
            style={"cursor: #{if @toggleable, do: "pointer", else: "default"};"}
          >
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  def dropzone(assigns) do
    ~H"""
    <div phx-hook="Drag" id="drag"> <!-- Here is our div with phx-hook and id attrs -->
    <div class="dropzone grid gap-3" id="pool">
        <%= for %{text: text, id: id} <- @pool do %>
        <div draggable="true" id="draggable" class="draggable p-4 bg-blue-700 text-white"><%= text %></div>
        <% end %>
    </div>
    </div>
  """
  end
end

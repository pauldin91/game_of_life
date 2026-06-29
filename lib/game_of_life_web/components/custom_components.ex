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
end

defmodule GameOfLifeWeb.CustomComponents do
  use Phoenix.Component

  attr :entry, :any, required: true
  @spec render_prop_input(map()) :: Phoenix.LiveView.Rendered.t()
  def render_prop_input(assigns) do
    ~H"""
    <div class="prop-input-wrapper">
      <div class="prop-input-header">
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
  attr :id, :string, required: true
  attr :toggleable, :boolean, default: false
  attr :dropzone, :boolean, default: false
  attr :data, :string, default: ""
  attr :cell_px, :integer, default: nil

  def board(assigns) do
    ~H"""
    <table
      id={@id}
      draggable={"#{!@dropzone}"}
      phx-hook={if @dropzone, do: "BoardDropzone", else: "Pattern"}
      data-pattern={if !@dropzone, do: @data}
      data-size={length(@matrix)}
      class={[
        "board-table",
        @dropzone && "board-dropzone"
      ]}
      style={
        if @cell_px do
          cols = if(@matrix == [], do: 0, else: length(hd(@matrix)))
          "width: #{@cell_px * cols}px;"
        else
          ""
        end
      }
    >
      <tbody>
        <tr :for={{row, i} <- Enum.with_index(@matrix, 0)}>
          <td
            :for={{cell, j} <- Enum.with_index(row, 0)}
            class={["board-cell",
              if(cell == 0, do: "board-cell-light", else: "board-cell-dark"),
              if(@toggleable, do: "board-cell-toggleable", else: "board-cell-static")
            ]}
            phx-click={if @toggleable, do: "toggle"}
            phx-value-i={i}
            phx-value-j={j}
            style={if @cell_px, do: "width: #{@cell_px}px; height: #{@cell_px}px;", else: "5px"}
          >
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end

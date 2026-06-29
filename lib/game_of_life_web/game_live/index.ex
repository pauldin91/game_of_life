defmodule GameOfLifeWeb.GameLive.Index do
  use GameOfLifeWeb, :live_view
  import GameOfLifeWeb.CustomComponents

  @default_size 5
  @default_delay 500

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_new(:size, fn -> @default_size end)
     |> assign_new(:delay, fn -> @default_delay end)
     |> assign(:running, false)
     |> assign(:board, GameOfLife.Engine.new_board(@default_size))}
  end

  @impl true
  def handle_event(
        "start",
        _params,
        %{assigns: %{running: false}} = socket
      ) do
    schedule_tick(socket)
    {:noreply, assign(socket, :running, true)}
  end

  def handle_event("start", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("size", %{"size" => value}, socket) do
    size = String.to_integer(value)
    dbg("size triggered")
    {:noreply, socket |> assign(:size, size) |> do_reset()}
  end

  @impl true
  def handle_event("delay", %{"delay" => value}, socket) do
    dbg("delay triggered")
    {:noreply, assign(socket, :delay, String.to_integer(value))}
  end

  @impl true
  def handle_event("reset", _params, socket), do: {:noreply, do_reset(socket)}

  @impl true
  def handle_info(:reset, socket), do: {:noreply, do_reset(socket)}

  def handle_info(:tick, %{assigns: %{running: true}} = socket) do
    schedule_tick(socket)
    {:noreply, assign(socket, :board, GameOfLife.Engine.tick(socket.assigns.board))}
  end

  def handle_info(:tick, socket), do: {:noreply, socket}

  defp do_reset(socket) do
    socket
    |> assign(:board, GameOfLife.Engine.new_board(socket.assigns.size))
    |> assign(:running, false)
    |> put_flash(:info, "Simulation ended")
  end

  defp schedule_tick(socket) do
    if GameOfLife.Engine.game_over?(socket.assigns.board) do
      Process.send(self(), :reset, [])
    else
      Process.send_after(self(), :tick, socket.assigns.delay)
    end
  end
end

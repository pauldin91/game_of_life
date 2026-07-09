defmodule GameOfLifeWeb.GameLive.Index do
  use GameOfLifeWeb, :live_view
  import GameOfLifeWeb.CustomComponents

  @default_size 12
  @default_delay 200
  @left_col_width 220
  @gap 64
  @padding 48
  @controls_h 160
  @default_mode "random"
  @modes [{"Random", "random"}, {"Custom", "custom"}]
  @initial_cell_px 20
  @phase2_threshold 48

  @impl true
  def mount(_params, _session, socket) do
    {:ok, patterns_pid} = GameOfLife.Patterns.start_link([])

    {:ok, board_pid} =
      GameOfLife.Orchestrator.start_link(size: @default_size, mode: @default_mode)

    max_board_px = min(600, @phase2_threshold * @initial_cell_px)

    {:ok,
     socket
     |> assign_new(:size, fn -> @default_size end)
     |> assign_new(:delay, fn -> @default_delay end)
     |> assign_new(:modes, fn -> @modes end)
     |> assign_new(:selected_mode, fn -> @default_mode end)
     |> assign(:running, false)
     |> assign(:patterns_pid, patterns_pid)
     |> assign(:board_pid, board_pid)
     |> assign(:board, GameOfLife.Orchestrator.board(board_pid))
     |> assign(:max_board_px, max_board_px)
     |> assign(:max_size, max_board_px)
     |> assign(:board_px, board_dims(@default_size, max_board_px))
     |> assign(:cell_px, cell_size(@default_size, max_board_px))}
  end

  @impl true
  def handle_event("size", %{"size" => value}, socket) do
    size =
      value
      |> String.to_integer()
      |> clamp(5, socket.assigns.max_size)

    max_board_px = socket.assigns.max_board_px

    {:noreply,
     socket
     |> assign(:size, size)
     |> assign(:board_px, board_dims(size, max_board_px))
     |> assign(:cell_px, cell_size(size, max_board_px))
     |> do_reset()}
  end

  @impl true
  def handle_event("delay", %{"delay" => value}, socket),
    do: {:noreply, assign(socket, :delay, String.to_integer(value))}

  @impl true
  def handle_event("reset", _params, socket), do: {:noreply, do_reset(socket)}

  @impl true
  def handle_event("pause", _params, socket), do: {:noreply, assign(socket, :running, false)}

  @impl true
  def handle_event("select_mode", _params, %{assigns: %{running: true}} = socket),
    do: {:noreply, socket}

  @impl true
  def handle_event("start", _params, %{assigns: %{running: false}} = socket) do
    schedule_tick(socket)
    {:noreply, assign(socket, :running, true)}
  end

  def handle_event("start", _params, socket), do: {:noreply, socket}

  def handle_event("select_mode", %{"selected_mode" => mode}, socket) do
    {:ok, pid} = GameOfLife.Orchestrator.start_link(size: socket.assigns.size, mode: mode)

    {:noreply,
     socket
     |> assign(:selected_mode, mode)
     |> assign(:board_pid, pid)
     |> assign(:board, GameOfLife.Orchestrator.board(pid))}
  end

  @impl true
  def handle_event("drop_pattern", %{"i" => i, "j" => j, "pattern" => pattern}, socket) do
    {:noreply,
     socket
     |> assign(
       :board,
       GameOfLife.Orchestrator.drop(socket.assigns.board_pid, %{
         "i" => i,
         "j" => j,
         "pattern" => pattern
       })
     )}
  end

  def handle_event("drop_pattern", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("toggle", %{"i" => i, "j" => j}, socket) do
    with :ok <-
           GameOfLife.Orchestrator.toggle_cell(
             socket.assigns.board_pid,
             %{"i" => String.to_integer(i), "j" => String.to_integer(j)}
           ),
         do:
           {:noreply,
            socket
            |> assign(
              :board,
              GameOfLife.Orchestrator.board(socket.assigns.board_pid)
            )}
  end

  @impl true
  def handle_event("screen_size", %{"width" => w, "height" => h}, socket) do
    max_board_px = compute_board_px(w, h)
    # cap max_board_px at the natural phase-1 ceiling so board never exceeds threshold size
    max_board_px = min(max_board_px, @phase2_threshold * @initial_cell_px)
    size = socket.assigns.size

    {:noreply,
     socket
     |> assign(:max_board_px, max_board_px)
     |> assign(:max_size, max_board_px)
     |> assign(:board_px, board_dims(size, max_board_px))
     |> assign(:cell_px, cell_size(size, max_board_px))}
  end

  @impl true
  def handle_info(:reset, socket), do: {:noreply, do_reset(socket)}

  @impl true
  def handle_info(:tick, %{assigns: %{running: false}} = socket), do: {:noreply, socket}

  def handle_info(:tick, %{assigns: %{running: true}} = socket) do
    schedule_tick(socket)
    {:noreply, assign(socket, :board, GameOfLife.Orchestrator.next(socket.assigns.board_pid))}
  end

  @impl true
  def handle_info(:gameover, socket) do
    {:noreply,
     socket
     |> assign(:running, false)
     |> put_flash(:info, "Gameover")}
  end

  defp do_reset(socket) do
    {:ok, board_pid} =
      GameOfLife.Orchestrator.start_link(
        size: socket.assigns.size,
        mode: socket.assigns.selected_mode
      )

    socket
    |> assign(
      :board_pid,
      board_pid
    )
    |> assign(:board, GameOfLife.Orchestrator.board(board_pid))
    |> assign(:running, false)
  end

  defp schedule_tick(socket) do
    if GameOfLife.Orchestrator.gameover?(socket.assigns.board_pid) do
      send(self(), :gameover)
    else
      Process.send_after(self(), :tick, socket.assigns.delay)
    end
  end

  defp compute_board_px(screen_w, screen_h) do
    available_w = screen_w - @left_col_width - @gap - @padding
    available_h = screen_h - @padding - @controls_h
    min(available_w, available_h)
  end

  defp board_dims(size, _max_board_px) when size <= @phase2_threshold,
    do: size * @initial_cell_px

  defp board_dims(_size, max_board_px), do: max_board_px

  defp cell_size(size, _max_board_px) when size <= @phase2_threshold, do: @initial_cell_px

  defp cell_size(size, max_board_px), do: max(1, div(max_board_px, size))

  defp clamp(value, min, max), do: value |> max(min) |> min(max)
end

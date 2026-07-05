defmodule GameOfLifeWeb.GameLive.Index do
  use GameOfLifeWeb, :live_view
  import GameOfLifeWeb.CustomComponents

  @default_size 12
  @default_delay 200
  @left_col_width 220
  @gap 64
  @padding 48
  @default_mode "random"
  @modes [{"Random", "random"}, {"Custom", "custom"}]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, patterns_pid} = GameOfLife.Patterns.start_link([])

    {:ok,
     socket
     |> assign_new(:size, fn -> @default_size end)
     |> assign_new(:delay, fn -> @default_delay end)
     |> assign_new(:modes, fn -> @modes end)
     |> assign_new(:selected_mode, fn -> @default_mode end)
     |> assign(:running, false)
     |> assign(:patterns_pid, patterns_pid)
     |> assign(:board, GameOfLife.Board.new_board(@default_size, @default_mode))
     |> assign(:board_px, 600)}
  end

  @impl true
  def handle_event("size", %{"size" => value}, socket),
    do:
      {:noreply,
       socket
       |> assign(:size, String.to_integer(value))
       |> do_reset()}

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
    {:noreply,
     socket
     |> assign(:selected_mode, mode)
     |> assign(:board, GameOfLife.Board.new_board(socket.assigns.size, mode))}
  end

  @impl true
  def handle_event("drop_pattern", %{"i" => i, "j" => j, "pattern" => pattern}, socket) do
    case GameOfLife.Board.drop(socket.assigns.board, i, j, pattern) do
      {:ok, board} ->
        {:noreply,
         socket
         |> assign(:board, board)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  def handle_event("drop_pattern", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("toggle", %{"i" => i, "j" => j}, socket),
    do:
      {:noreply,
       socket
       |> assign(
         :board,
         GameOfLife.Board.toggle_cell(
           socket.assigns.board,
           String.to_integer(i),
           String.to_integer(j)
         )
       )}

  @impl true
  def handle_event("screen_size", %{"width" => w, "height" => h}, socket) do
    board_px = compute_board_px(w, h)
    {:noreply, assign(socket, :board_px, board_px)}
  end

  @impl true
  def handle_info(:reset, socket), do: {:noreply, do_reset(socket)}

  @impl true
  def handle_info(:tick, %{assigns: %{running: false}} = socket), do: {:noreply, socket}

  def handle_info(:tick, %{assigns: %{running: true}} = socket) do
    schedule_tick(socket)
    {:noreply, assign(socket, :board, GameOfLife.Engine.tick(socket.assigns.board))}
  end

  @impl true
  def handle_info(:gameover, socket) do
    {:noreply,
     socket
     |> assign(:running, false)
     |> put_flash(:info, "Gameover")}
  end

  defp do_reset(socket) do
    socket
    |> assign(
      :board,
      GameOfLife.Board.new_board(socket.assigns.size, socket.assigns.selected_mode)
    )
    |> assign(:running, false)
  end

  defp schedule_tick(socket) do
    if GameOfLife.Board.game_over?(socket.assigns.board) do
      send(self(), :gameover)
    else
      Process.send_after(self(), :tick, socket.assigns.delay)
    end
  end

  defp compute_board_px(screen_w, screen_h) do
    available_w = screen_w - @left_col_width - @gap - @padding
    available_h = screen_h - @padding
    min(available_w, available_h)
  end
end

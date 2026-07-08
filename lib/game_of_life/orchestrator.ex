defmodule GameOfLife.Orchestrator do
  alias GameOfLife.Orchestrator
  use GenServer

  defstruct [:size, :mode, :board, gen: 0, alive: 0]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def next(pid), do: GenServer.call(pid, :next)
  def board(pid), do: GenServer.call(pid, :board)
  def gameover?(pid), do: GenServer.call(pid, :gameover)
  def alive(pid), do: GenServer.call(pid, :alive)
  def σιζε(pid, size), do: GenServer.cast(pid, {:size, size})
  def toggle_cell(pid, i, j), do: GenServer.cast(pid, {:toggle, %{i: i, j: j}})
  def drop(pid, %{i: _i, j: _j, pattern: _pattern} = item), do: GenServer.cast(pid, {:drop, item})

  @impl true
  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    mode = Keyword.fetch!(opts, :mode)
    board = new_board(size, mode)

    {:ok,
     %Orchestrator{
       size: size,
       mode: mode,
       board: board,
       gen: 0,
       alive: Enum.count(board)
     }}
  end

  @impl true
  def handle_call(:alive, _from, %__MODULE__{} = state) do
    {:reply, state.alive, state}
  end

  @impl true
  def handle_call(:next, _from, %__MODULE__{} = state) do
    dbg(state.board)

    board =
      Enum.map(state.board, fn
        {k, v} ->
          total = calculate_cell(state.board, k, state.size)

          cond do
            total == 3 -> {k, 1}
            2 <= total and total <= 3 and v == 1 -> {k, v}
            true -> {k, 0}
          end
      end)
      |> Enum.filter(fn {_k, v} -> v == 1 end)
      |> Map.new()

    dbg(board)

    new_state = %__MODULE__{
      state
      | board: board,
        alive: Enum.count(state.board),
        gen: state.gen + 1
    }

    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:gameover, _from, state) do
    {:reply, state.alive == 0 && state.gen > 0, state}
  end

  @impl true
  def handle_call(:board, _from, %__MODULE__{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:toggle, %{i: i, j: j}}, %Orchestrator{} = state) do
    board =
      Map.update(state.board, i * state.size + j, nil, fn {_x, y} ->
        cond do
          1 - y == 1 -> 1
          true -> nil
        end
      end)

    new_state = %Orchestrator{state | board: board}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:size, size}, %Orchestrator{} = state) do
    {:noreply, %Orchestrator{state | board: new_board(size, state.mode), size: size}}
  end

  @impl true
  def handle_cast({:drop, %{i: _i, j: _j, pattern: _pattern}}, %Orchestrator{} = state) do
    {:noreply, %Orchestrator{state | board: state.board}}
  end

  defp new_board(_size, "custom") do
    Map.new()
  end

  defp new_board(size, "random") do
    r = 0..(size * size - 1)

    Enum.zip(
      r,
      Enum.map(r, fn _ -> :rand.uniform(2) - 1 end)
    )
    |> Enum.filter(fn {_x, y} -> y == 1 end)
    |> Map.new()
  end

  defp get_side(start, step) do
    (start - step)..(start + step)//step |> Enum.map(& &1)
  end

  defp indices(i, size) do
    r = rem(i, size)
    right = get_side(i + 1, size)
    left = get_side(i - 1, size)

    [i - size, i + size] ++
      cond do
        r == 0 -> right
        r == size - 1 -> left
        true -> left ++ right
      end
  end

  defp calculate_cell(the_map, i, size) do
    indices(i, size)
    |> Enum.map(fn i -> Map.get(the_map, i, 0) end)
    |> Enum.sum()
  end
end

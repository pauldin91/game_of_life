defmodule GameOfLife.Orchestrator do
  alias GameOfLife.Orchestrator
  use GenServer

  defstruct [:size, :mode, :board, gen: 0, alive: 0]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def next(pid), do: GenServer.call(pid, :next)
  def board(pid), do: GenServer.call(pid, :board)
  def gameover?(pid), do: GenServer.call(pid, :gameover)
  def alive(pid), do: GenServer.call(pid, :alive)
  def size(pid, size), do: GenServer.cast(pid, {:size, size})
  def toggle_cell(pid, %{"i" => _i, "j" => _j} = cell), do: GenServer.cast(pid, {:toggle, cell})

  def drop(pid, %{"i" => _i, "j" => _j, "pattern" => _pattern} = item),
    do: GenServer.cast(pid, {:drop, item})

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
    keys =
      Map.keys(state.board)
      |> Enum.flat_map(&indices(&1, state.size))
      |> Enum.uniq()

    board =
      Enum.flat_map(keys, fn k ->
        v = Map.get(state.board, k, 0)
        total = calculate_cell(state.board, k, state.size)

        cond do
          total == 3 -> [{k, 1}]
          total == 2 and v == 1 -> [{k, 1}]
          true -> []
        end
      end)
      |> Map.new()

    new_state = %__MODULE__{
      state
      | board: board,
        alive: Enum.count(board),
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
  def handle_cast({:toggle, %{"i" => i, "j" => j}}, %Orchestrator{} = state) do
    key = i * state.size + j

    board =
      if Map.has_key?(state.board, key),
        do: Map.delete(state.board, key),
        else: Map.put(state.board, key, 1)

    {:noreply, %Orchestrator{state | board: board}}
  end

  @impl true
  def handle_cast({:size, size}, %Orchestrator{} = state) do
    {:noreply, %Orchestrator{state | board: new_board(size, state.mode), size: size}}
  end

  @impl true
  def handle_cast(
        {:drop, %{"i" => i, "j" => j, "pattern" => pattern} = item},
        %Orchestrator{} = state
      ) do
    mid =
      %{
        board: pattern["board"] |> Map.new(fn {x, y} -> {String.to_integer(x), y} end),
        size: pattern["size"]
      }

    offset = i * state.size + j

    at =
      0..(mid.size * mid.size + 1)
      |> Enum.map(fn x ->
        {x + offset, Map.get(mid.board, x, 0)}
      end)
      |> Map.new()

    pat =
      make_map(%{board: at, size: mid.size}, offset, state.size)

    board = Map.merge(state.board, pat)
    {:noreply, %Orchestrator{state | board: board}}
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

  defp make_map(matrix, offset, global_mat_size) do
    Enum.zip(
      Enum.with_index(
        offset..(offset + matrix.size * matrix.size - 1)
        |> Enum.chunk_every(matrix.size)
      )
      |> Enum.map(fn {x, i} ->
        Enum.map(x, fn y -> y + i * (global_mat_size - matrix.size) end)
      end)
      |> Enum.reduce([], fn x, acc -> acc ++ x end),
      Enum.sort(matrix.board, fn e1, e2 -> elem(e1, 0) < elem(e2, 0) end)
      |> Enum.map(fn {_i, x} -> x end)
    )
    |> Enum.filter(fn {_x, v} -> v == 1 end)
    |> Map.new(fn {k, v} ->
      {k, v}
    end)
  end
end

defmodule GameOfLife.Orchestrator do
  alias GameOfLife.Orchestrator
  use GenServer

  defstruct [:size, :mode, :board, gen: 0, alive: 0]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def next(pid), do: GenServer.call(pid, :next)
  def toggle_cell(pid, i, j), do: GenServer.cast(pid, {:toggle, %{i: i, j: j}})
  def gameover?(pid), do: GenServer.call(pid, :gameover)

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
       alive: 0
     }}
  end

  @impl true
  def handle_call(:next, _from, %__MODULE__{} = state) do
    board = tick(state.board)

    new_state = %__MODULE__{
      state
      | board: board,
        alive: alive(board),
        gen: state.gen + 1
    }

    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:gameover, _from, state) do
    {:reply, state.alive == 0, state}
  end

  @impl true
  def handle_cast({:toggle, %{i: i, j: j}}, %Orchestrator{} = state) do
    new_state = %Orchestrator{state | board: toggle(state.board, i, j)}
    {:noreply, new_state}
  end

  def new_board(size, "custom") do
    0..(size - 1)
    |> Enum.map(fn _ ->
      0..(size - 1)
      |> Enum.map(fn _ -> 0 end)
    end)
  end

  def new_board(size, "random") do
    0..(size - 1)
    |> Enum.map(fn _ ->
      0..(size - 1)
      |> Enum.map(fn _ -> :rand.uniform(2) - 1 end)
    end)
  end

  def drop(matrix, i, j, pattern) do
    do_replace(matrix, i, j, pattern)
  end

  def do_replace(matrix, i, j, pattern) do
    size = Enum.count(Enum.at(matrix, 0))

    pat =
      make_map(
        pattern,
        (i - 1) * size + j - 1,
        size
      )

    mat = make_map(matrix, 0, size)

    res =
      Enum.map(mat, fn {x, y} ->
        repl = Map.get(pat, x, nil)

        cond do
          repl == nil -> {x, y}
          true -> {x, repl}
        end
      end)
      |> Enum.sort(fn e1, e2 -> elem(e1, 0) < elem(e2, 0) end)
      |> Enum.map(fn {_i, v} -> v end)
      |> Enum.chunk_every(length(matrix))

    {:ok, res}
  end

  defp make_map(matrix, offset, global_mat_size) do
    size = Enum.count(Enum.at(matrix, 0))

    Enum.zip(
      Enum.with_index(
        offset..(offset + length(matrix) * size - 1)
        |> Enum.chunk_every(size)
      )
      |> Enum.map(fn {x, i} -> Enum.map(x, fn y -> y + i * (global_mat_size - size) end) end)
      |> Enum.reduce([], fn x, acc -> acc ++ x end),
      Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
    )
    |> Map.new(fn {k, v} ->
      {k, v}
    end)
  end

  def alive(matrix), do: Enum.reduce(matrix, 0, fn x, acc -> acc + Enum.sum(x) end)

  def game_over?(matrix) do
    sum = alive(matrix)

    cond do
      sum == 0 -> true
      true -> false
    end
  end

  def toggle(matrix, i, j) do
    size = Enum.count(Enum.at(matrix, 0))

    Enum.zip(
      0..(length(matrix) * size - 1),
      Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
    )
    |> Enum.map(fn {x, y} ->
      cond do
        i * size + j == x -> 1 - y
        true -> y
      end
    end)
    |> Enum.chunk_every(size)
  end

  @spec tick(matrix :: list(list(0 | 1))) :: list(list(0 | 1))
  def tick([]), do: []

  def tick(matrix) do
    size = length(matrix)

    make_map(matrix, size)
    |> apply_rules(size)
    |> Enum.sort(fn e1, e2 -> elem(e1, 0) < elem(e2, 0) end)
    |> Enum.map(fn {_i, v} -> v end)
    |> Enum.chunk_every(size)
  end

  defp make_map(matrix, size),
    do:
      Enum.zip(
        0..(size * size - 1),
        Enum.reduce(matrix, [], fn x, acc -> acc ++ x end)
      )
      |> Map.new()

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

  defp apply_rules(the_map, size) do
    Enum.map(the_map, fn
      {i, v} ->
        total = calculate_cell(the_map, i, size)

        cond do
          total == 3 -> {i, 1}
          2 <= total and total <= 3 and v == 1 -> {i, v}
          true -> {i, 0}
        end
    end)
  end

  defp calculate_cell(the_map, i, size) do
    indices(i, size)
    |> Enum.map(fn i -> Map.get(the_map, i, 0) end)
    |> Enum.sum()
  end
end

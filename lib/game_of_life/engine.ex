defmodule GameOfLife.Engine do
  alias GameOfLife.Engine
  use GenServer

  defstruct [:rows, :cols, :mode, :board, gen: 0, alive: 0]

  @spec new(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def new(opts), do: GenServer.start_link(__MODULE__, opts)

  def next(pid), do: GenServer.call(pid, :next)
  def board(pid), do: GenServer.call(pid, :board)
  def gameover?(pid), do: GenServer.call(pid, :gameover)
  def alive(pid), do: GenServer.call(pid, :alive)

  def size(pid, %{"rows" => _rows, "cols" => _cols} = size),
    do: GenServer.cast(pid, {:size, size})

  def toggle_cell(pid, %{"i" => _i, "j" => _j} = cell), do: GenServer.cast(pid, {:toggle, cell})

  def drop(pid, %{"i" => _i, "j" => _j, "pattern" => _pattern} = item),
    do: GenServer.cast(pid, {:drop, item})

  @impl true
  def init(opts) do
    rows = Keyword.fetch!(opts, :rows)
    cols = Keyword.fetch!(opts, :cols)
    mode = Keyword.fetch!(opts, :mode)

    board =
      case Keyword.fetch(opts, :board) do
        {:ok, board} -> board
        _ -> GameOfLife.Board.new_board(%{"rows" => rows, "cols" => cols}, mode)
      end

    {:ok,
     %Engine{
       rows: rows,
       cols: cols,
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
      |> Enum.flat_map(&GameOfLife.Board.indices(&1, state.rows, state.cols))
      |> Enum.uniq()

    board =
      Enum.flat_map(keys, fn k ->
        v = Map.get(state.board, k, 0)
        total = GameOfLife.Board.calculate_cell(state.board, k, state.rows, state.cols)

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
  def handle_cast({:toggle, %{"i" => i, "j" => j}}, %Engine{} = state) do
    key = i * state.cols + j

    board =
      if Map.has_key?(state.board, key),
        do: Map.delete(state.board, key),
        else: Map.put(state.board, key, 1)

    {:noreply, %Engine{state | board: board}}
  end

  @impl true
  def handle_cast({:size, %{"rows" => rows, "cols" => cols} = size}, %Engine{} = state) do
    {:noreply,
     %Engine{state | board: GameOfLife.Board.new_board(size, state.mode), rows: rows, cols: cols}}
  end

  @impl true
  def handle_cast(
        {:drop, %{"i" => i, "j" => j, "pattern" => pattern}},
        %Engine{} = state
      ) do
    mid =
      %{
        board: pattern["board"] |> Map.new(fn {x, y} -> {String.to_integer(x), y} end),
        rows: pattern["rows"],
        cols: pattern["cols"]
      }

    offset = i * state.cols + j

    at =
      0..(mid.rows * mid.cols + 1)
      |> Enum.map(fn x ->
        {x + offset, Map.get(mid.board, x, 0)}
      end)
      |> Map.new()

    pat =
      make_map(%{board: at, rows: mid.rows, cols: mid.cols}, offset, state.cols)

    board = Map.merge(state.board, pat)
    {:noreply, %Engine{state | board: board}}
  end

  defp make_map(matrix, offset, global_cols) do
    Enum.zip(
      Enum.with_index(
        offset..(offset + matrix.rows * matrix.cols - 1)
        |> Enum.chunk_every(matrix.cols)
      )
      |> Enum.map(fn {x, i} ->
        Enum.map(x, fn y -> y + i * (global_cols - matrix.cols) end)
      end)
      |> Enum.reduce([], fn x, acc -> acc ++ x end),
      Enum.sort(matrix.board, fn e1, e2 -> elem(e1, 0) < elem(e2, 0) end)
      |> Enum.map(fn {_i, x} -> x end)
    )
    |> Enum.filter(fn {_x, v} -> v == 1 end)
    |> Map.new()
  end
end

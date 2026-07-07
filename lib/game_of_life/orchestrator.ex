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
    board = GameOfLife.Board.new_board(size, mode)

    {:ok,
     %Orchestrator{
       size: size,
       mode: mode,
       board: board,
       gen: 0,
       alive: GameOfLife.Board.alive(board)
     }}
  end

  @impl true
  def handle_call(:next, _from, %__MODULE__{} = state) do
    board = GameOfLife.Engine.tick(state.board)

    new_state = %__MODULE__{
      state
      | board: board,
        alive: GameOfLife.Board.alive(board),
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
    new_state = %Orchestrator{state | board: GameOfLife.Board.toggle_cell(state.board, i, j)}
    {:noreply, new_state}
  end
end

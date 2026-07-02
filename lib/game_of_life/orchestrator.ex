defmodule GameOfLife.Orchestrator do
  use GenServer

  defstruct [:size, :mode, :board, gen: 0, alive: 0]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def next(pid), do: GenServer.call(pid, :next)

  @impl true
  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    mode = Keyword.fetch!(opts, :mode)
    board = GameOfLife.Board.new_board(size, mode)

    {:ok,
     %__MODULE__{
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
end

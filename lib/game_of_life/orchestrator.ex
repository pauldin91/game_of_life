defmodule GameOfLife.Orchestrator do
  use GenServer

  defstruct [:size, :mode, :board, :gen, :alive]

  def start(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    mode = Keyword.fetch!(opts, :mode)
    {:ok, %{board: GameOfLife.Board.new_board(size, mode)}}
  end

  def handle_call(request, from, state) do
  end
end

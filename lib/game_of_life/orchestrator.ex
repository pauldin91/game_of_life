defmodule GameOfLife.Orchestrator do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    {:ok, %{board: GameOfLife.Engine.new_board(size)}}
  end
end

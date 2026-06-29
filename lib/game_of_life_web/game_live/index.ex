defmodule GameOfLifeWeb.GameLive.Index do
  use GameOfLifeWeb, :live_view
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :board, GameOfLife.Engine.new_board(8))}
  end

  @impl true
  def handle_event("next", _map, socket) do
    {:noreply, assign(socket, :board, GameOfLife.Engine.new_board(9))}
  end

  # @impl true
  # def handle_info() do
  # end
end

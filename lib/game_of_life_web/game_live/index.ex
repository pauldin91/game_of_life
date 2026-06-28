defmodule GameOfLifeWeb.GameLive do
   use GameOfLifeWeb, :live_view
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :board, GameOfLife.Engine.new_board(4))}
  end

  @impl true
  def handle_event() do
  end

  @impl true
  def handle_info() do
  end
end

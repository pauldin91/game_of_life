defmodule GameOfLife.Patterns do
  use GenServer

  @sorter %{"oscillators" => 1, "still" => 2, "spaceships" => 3}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [])

  def all(pid), do: GenServer.call(pid, :all)
  def get(pid, pattern), do: GenServer.call(pid, {:get, pattern})

  @impl true
  def init(_opts) do
    with {:ok, contents} <- File.read("patterns.json"),
         {:ok, serialized} <- Jason.decode(contents) do
      {:ok,
       serialized
       |> Enum.sort(fn x,y -> Map.get(@sorter,elem(x,0),0) > Map.get(@sorter,elem(y,0),0)  end)}
    end
  end

  @impl true
  def handle_call({:get, pattern}, _from, state) do
    {:reply, Map.get(state, pattern), state}
  end

  @impl true
  def handle_call(:all, _from, patterns) do
    {:reply, patterns, patterns}
  end
end

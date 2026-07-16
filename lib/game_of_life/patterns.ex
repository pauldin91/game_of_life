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
      {
        :ok,
        serialized
        |> Enum.map(fn {name, %{"board" => b, "rows" => r, "cols" => c}} ->
          {name, {r, c, as_map(b)}}
        end)
        |> Enum.sort(fn {n1, _}, {n2, _} -> Map.get(@sorter, n1) < Map.get(@sorter, n2) end)
        |> Map.new()
      }
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

  def as_map(pattern) do
    Enum.with_index(Enum.reduce(pattern, [], fn t, acc -> acc ++ t end), 0)
    |> Enum.filter(fn {v, _k} -> v == 1 end)
    |> Map.new(fn {v, k} -> {k, v} end)
  end
end

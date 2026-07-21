defmodule EngineTest do
  use ExUnit.Case
  alias GameOfLife.Engine

  #
  test "empty matrix" do
    {:ok, pid} = Engine.new(rows: 4, cols: 4, mode: "custom")
    ngin = Engine.next(pid)
    assert ngin.gen == 1
    assert ngin.alive == 0
    assert ngin.board == %{}
    assert ngin.mode == "custom"
    assert ngin.rows == 4
    assert ngin.cols == 4
  end

  test "live cells with zero live neighbors die" do
    matrix = %{4 => 1}
    output = %{}

    {:ok, pid} = Engine.new(rows: 3, cols: 3, mode: "custom", board: matrix)
    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == 0
  end

  test "live cells with only one live neighbor die" do
    matrix = %{4 => 1, 7 => 1}
    output = %{}

    {:ok, pid} = Engine.new(rows: 3, cols: 3, mode: "custom", board: matrix)
    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == 0
  end

  test "live cells with two live neighbors stay alive" do
    matrix = %{0 => 1, 2 => 1, 3 => 1, 5 => 1, 6 => 1, 8 => 1}
    output = %{3 => 1, 5 => 1}

    {:ok, pid} = Engine.new(rows: 3, cols: 3, mode: "custom", board: matrix)
    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == 2
  end

  test "live cells with three live neighbors stay alive" do
    matrix = %{1 => 1, 3 => 1, 6 => 1, 7 => 1}
    output = %{3 => 1, 6 => 1, 7 => 1}

    {:ok, pid} = Engine.new(rows: 3, cols: 3, mode: "custom", board: matrix)
    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == 3
  end

  test "dead cells with three live neighbors become alive" do
    matrix = %{0 => 1, 1 => 1, 6 => 1}
    output = %{3 => 1, 4 => 1}

    {:ok, pid} = Engine.new(rows: 3, cols: 3, mode: "custom", board: matrix)
    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == 2
  end

  test "live cells with four or more neighbors die" do
    matrix = 0..8 |> Enum.map(&{&1, 1}) |> Map.new()
    output = %{0 => 1, 2 => 1, 6 => 1, 8 => 1}

    {:ok, pid} = Engine.new(rows: 3, cols: 3, mode: "custom", board: matrix)
    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == 4
  end

  test "bigger matrix" do
    matrix =
      0..63
      |> Enum.zip([
        [1, 1, 0, 1, 1, 0, 0, 0],
        [1, 0, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 0, 0, 1, 1, 1],
        [0, 0, 0, 0, 0, 1, 1, 0],
        [1, 0, 0, 0, 1, 1, 0, 0],
        [1, 1, 0, 0, 0, 1, 1, 1],
        [0, 0, 1, 0, 1, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1, 1]
      ])
      |> Enum.filter(fn {_k, v} -> v == 1 end)
      |> Map.new()

    output =
      0..63
      |> Enum.zip([
        [1, 1, 0, 1, 1, 0, 0, 0],
        [0, 0, 0, 0, 0, 1, 1, 0],
        [1, 0, 1, 1, 1, 1, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 0, 0, 1, 0, 0, 1],
        [1, 1, 0, 1, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 1, 1]
      ])
      |> Enum.filter(fn {_k, v} -> v == 1 end)
      |> Map.new()

    {:ok, pid} = Engine.new(rows: 8, cols: 8, mode: "custom", board: matrix)

    ngin = Engine.next(pid)
    assert ngin.board == output
    assert ngin.alive == Enum.count(output)
  end
end

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
    matrix = %{4=>1}
    {:ok, pid} = Engine.new([rows: 3, cols: 3,mode: "custom",board: matrix])
    output = %{}
    Engine.next(pid).board == output
  end

  test "live cells with only one live neighbor die" do
    matrix = [[0, 0, 0], [0, 1, 0], [0, 1, 0]]
    output = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]

    assert Engine.tick(matrix) == output
  end

  test "live cells with two live neighbors stay alive" do
    matrix = [[1, 0, 1], [1, 0, 1], [1, 0, 1]]
    output = [[0, 0, 0], [1, 0, 1], [0, 0, 0]]

    assert Engine.tick(matrix) == output
  end

  test "live cells with three live neighbors stay alive" do
    matrix = [[0, 1, 0], [1, 0, 0], [1, 1, 0]]
    output = [[0, 0, 0], [1, 0, 0], [1, 1, 0]]

    assert Engine.tick(matrix) == output
  end

  test "dead cells with three live neighbors become alive" do
    matrix = [[1, 1, 0], [0, 0, 0], [1, 0, 0]]
    output = [[0, 0, 0], [1, 1, 0], [0, 0, 0]]

    assert Engine.tick(matrix) == output
  end

  test "live cells with four or more neighbors die" do
    matrix = [[1, 1, 1], [1, 1, 1], [1, 1, 1]]
    output = [[1, 0, 1], [0, 0, 0], [1, 0, 1]]

    assert Engine.tick(matrix) == output
  end

  test "bigger matrix" do
    matrix = [
      [1, 1, 0, 1, 1, 0, 0, 0],
      [1, 0, 1, 1, 0, 0, 0, 0],
      [1, 1, 1, 0, 0, 1, 1, 1],
      [0, 0, 0, 0, 0, 1, 1, 0],
      [1, 0, 0, 0, 1, 1, 0, 0],
      [1, 1, 0, 0, 0, 1, 1, 1],
      [0, 0, 1, 0, 1, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 1, 1]
    ]

    output = [
      [1, 1, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 0, 1, 1, 0],
      [1, 0, 1, 1, 1, 1, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 1],
      [1, 1, 0, 0, 1, 0, 0, 1],
      [1, 1, 0, 1, 0, 0, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 1, 1]
    ]

    assert Engine.tick(matrix) == output
  end
end

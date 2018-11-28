defmodule BrainfuckTest do
  use ExUnit.Case
  doctest Brainfuck

  test "greets the world" do
    assert Brainfuck.hello() == :world
  end
end

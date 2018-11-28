defmodule Brainfuck do
  # @input nil
  # @output nil
  # @storage []
  # @ops 0

  # @buffer 0
  # @buffer_bytes 0

  # @current_loop_program []

  # @timeout false

  def fuck(program) do
    program =
      program
      |> String.trim()
      |> String.split("\n")

    info = program |> Enum.at(0)
    input = program |> Enum.at(1)

    # {cell = 0, cells = [], loop = [], output = []}
    state = {0, [{0, 0}], []}

    program =
      program
      |> Enum.join(" ")
      |> String.graphemes()
      |> Enum.map(fn c ->
        case c do
          "[" -> c
          ">" -> c
          "<" -> c
          "+" -> c
          "-" -> c
          "," -> c
          "." -> c
          "]" -> c
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> brainfuck(state)
      |> IO.puts()
  end

  def brainfuck(_list, nil), do: IO.puts("Not sure what's wrong")

  def brainfuck([], {_cell, _storage, output}), do: IO.puts(output)

  def brainfuck([h | t], {cell, storage, output} = state) do
    state = code(h, state)
    next = List.first(t)
    {:ok, lookahead} = get_loop(t)

    # IO.inspect(state)

    maybe_loop_state =
      if h == "[" do
        {:ok, lookahead} = get_loop(t)
        IO.puts("looking ahead")
        IO.inspect(lookahead)

        t = t -- lookahead
        t = t -- ["]"]

        if length(lookahead) == 1 do
          do_loop(Enum.at(lookahead, 0), state)
        else
          do_loop(lookahead, state)
        end
      else
        state
      end

    # I DONT FUCKING KNOW
    # This is getting stuck because it's finishing off where maybe_loop_state left off!! Need to get rid of everything that was in the loop.
    # Maybe do what I was doing before with the case statement, but add a

    brainfuck(t, maybe_loop_state)
  end

  def do_loop([], {cell, storage, output}), do: {cell, storage, output}

  def do_loop([h | t] = list, {cell, storage, output}) when is_list(list) do
    {_c, v} = storage |> Enum.at(cell)

    state =
      case v do
        0 ->
          {cell, storage, output}

        _ ->
          {c, s, o} = code(h, {cell, storage, output})
          do_loop(t, {c, s, o})
      end

    state
  end

  def do_loop(command, {cell, storage, output}) when is_bitstring(command) do
    {_c, v} = storage |> Enum.at(cell)

    state =
      case v do
        0 ->
          {cell, storage, output}

        _ ->
          {c, s, o} = code(command, {cell, storage, output})

          do_loop(command, {c, s, o})
      end

    state
  end

  # def handle_loop(code, {cell, storage, output}) do
  #   if v == 0, do: {cell, storage, output}

  #   if v != 0 do
  #     ns = {c, s, o} = code(command, {cell, storage, output})
  #     st = {_c, v} = storage |> Enum.at(cell)
  #     do_loop(command, {c, s, o})
  #   end
  # end

  def debug(command, {cell, storage, output} = state) do
    cmd = Atom.to_string(command)
    {c, v} = get_cell(storage, cell)
    IO.puts("#{cmd} for cell ##{cell} |> value is #{v}")
    IO.inspect(state)
  end

  def code(">", state), do: handle_code(:cell_increment, state)
  def code("<", state), do: handle_code(:cell_decrement, state)

  def code("+", state), do: handle_code(:byte_increment, state)
  def code("-", state), do: handle_code(:byte_decrement, state)

  def code(".", state), do: handle_output(state)
  def code(",", state), do: handle_read_byte(state)

  def code("[", state), do: handle_loop_start(state)
  def code("]", state), do: handle_loop_end(state)

  def handle_code(:cell_increment, {cell, storage, output} = state) do
    state = {cell + 1, storage ++ [{cell, 0}], output}
    debug(:cell_increment, state)
    state
  end

  def handle_code(:cell_decrement, {cell, storage, output} = state) do
    state = {cell - 1, storage, output}
    debug(:cell_decrement, state)
    state
  end

  def handle_code(:byte_increment, {cell, storage, output} = state) do
    storage =
      storage
      |> Enum.map(fn {c, v} ->
        with {cell, value} <- {c, v} do
          {cell, value + 1}
        end
      end)

    state = {cell, storage, output}
    debug(:byte_increment, state)
    state
  end

  def handle_code(:byte_decrement, {cell, storage, output} = state) do
    storage =
      storage
      |> Enum.map(fn {c, v} ->
        with {cell, value} <- {c, v} do
          {cell, value - 1}
        end
      end)

    state = {cell, storage, output}
    debug(:byte_decrement, state)
    state
  end

  defp get_loop([], acc), do: {:ok, acc}

  defp get_loop([h | t], acc \\ []) do
    if h == "]" do
      {:ok, acc}
    else
      acc = acc ++ [h]
      get_loop(t, acc)
    end
  end

  defp get_cell(storage, cell), do: Enum.at(storage, cell)

  defp handle_byte_increment({cell, storage, output}) do
    # IO.puts("+ byte +1")

    storage =
      storage
      |> Enum.map(fn {c, v} ->
        with {cell, value} <- {c, v} do
          {cell, value + 1}
        end
      end)

    {cell, storage, output}
  end

  defp handle_byte_decrement({cell, storage, output} = state) do
    # IO.puts("- byte -1")
    storage =
      storage
      |> Enum.map(fn {c, v} ->
        with {cell, value} <- {c, v} do
          {cell, value - 1}
        end
      end)

    {cell, storage, output}
  end

  defp handle_output({cell, storage, output}) do
    # IO.puts(". output current byte in buffer")
    {_c, v} = Enum.at(storage, cell)
    {cell, storage, output ++ [<<v::utf8>>]}
  end

  defp handle_read_byte({cell, storage, output} = state) do
    # IO.puts(", read byte")
    state
  end

  defp handle_loop_start({cell, storage, output} = state) do
    # IO.puts("[ loop start")
    state
  end

  defp handle_loop_end({cell, storage, output} = state) do
    # IO.puts("] loop end")
    state
  end
end

# Brainfuck.fuck("""
# 0 1
# $
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++..
# """)

# Brainfuck.fuck("""
# 0 20
# $
# >+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.[-]
# >++++++++[<++++>-] <.>+++++++++++[<++++++++>-]<-.--------.+++
# .------.--------.[-]>++++++++[<++++>- ]<+.[-]++++++++++.
# """)

Brainfuck.fuck("""
0 20
$
+++++ +++++             initialize counter (cell #0) to 10
[                       use loop to set the next four cells to 70/100/30/10
    > +++++ ++              add  7 to cell #1
    > +++++ +++++           add 10 to cell #2
    > +++                   add  3 to cell #3
    > +                     add  1 to cell #4
    <<<< -                  decrement counter (cell #0)
]
> ++ .                  print 'H'
> + .                   print 'e'
+++++ ++ .              print 'l'
.                       print 'l'
+++ .                   print 'o'
> ++ .                  print ' '
<< +++++ +++++ +++++ .  print 'W'
> .                     print 'o'
+++ .                   print 'r'
----- - .               print 'l'
----- --- .             print 'd'
> + .                   print '!'
""")

# Brainfuck.fuck("""
# 0 20
# $
# +++++[-]
# """)

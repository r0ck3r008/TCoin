defmodule M do
  def hello do
     #IO.puts "Chicken is my religion"
     #spawn(fn() -> loop(20, 10) end)
     #spawn(fn() -> loop(9, 0) end)
     n = 1260
     a = rem(n,10)
     t1 = div(n,10)
     b = rem(t1,10)
     t2 = div(n, 100)
     c = rem(t2, 10)
     t3 = div(n, 1000)
     d = rem(t3,10)

     #permutations([a,b,c,d])

     Enum.each(permutations([a,b,c,d]), fn(x) ->
       IO.puts String.to_integer(Enum.join(x, ""))

     end)
     #IO.puts "Perm List is : #{perm_list}"

  end


  def permutations([]), do: [[]]
  def permutations(list), do: for elem <- list, rest <- permutations(list--[elem]), do: [elem|rest]

  def loop(0,_), do: nil

  def loop(max, min) do
    if max < min do
      loop(0, min)
    else
      IO.puts "Num is #{max}"
      loop(max - 1, min)
    end
  end
end

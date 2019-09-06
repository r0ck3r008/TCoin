defmodule M do

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def hello(n1, n2) do

     M.start_link

    #    n1 = IO.gets("Enter Starting Number: ")    |> String.strip |> String.to_integer
    #n2 = IO.gets("Enter Ending Number: ")    |> String.strip |> String.to_integer

     range = n2-n1
     interval = div(range, 5)

     spawn(fn() -> loop(n1, n1+interval) end)
     spawn(fn() -> loop(n1+interval+1, n1+interval*2) end)
     spawn(fn() -> loop(n1+interval*2+1, n1+interval*3) end)
     spawn(fn() -> loop(n1+interval*3+1, n1+interval*4) end)
     spawn(fn() -> loop(n1+interval*4+1, n2) end)

     v = Agent.get(__MODULE__, fn(state) -> state end)
    Enum.each(v, fn ({key, value}) -> IO.puts "#{key} : #{Enum.join(value, " ")}" end)

    :timer.sleep(100000)

  end

  def pow(_, 0), do: 1
  def pow(k, n) when rem(n,2) == 1, do: k * pow(k, n - 1)
  def pow(k, n) do
  result = pow(k, div(n, 2))
  result * result
  end


  def loop(0,_), do: nil

  def loop(min, max) do

    if max < min do
      loop(0, min)
    else
      if rem(length(Integer.digits(min)), 2) == 0 do
        #IO.puts "Num is #{min} and length is #{length(Integer.digits(min))}"
        Enum.each(permutations(Integer.digits(min)), fn(x) ->

          if div(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2)))*rem(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2))) == min do

              #IO.puts "#{min} " <> Integer.to_string(div(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2)))) <> " " <> Integer.to_string(rem(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2))))

              Agent.update(__MODULE__, fn(state) ->

              Map.update(state, :"#{min}", [div(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2))), rem(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2)))], &(

              if !Enum.member?(Map.get(state, :"#{min}"), rem(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2)))) do
                &1 ++ [div(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2))), rem(String.to_integer(Enum.join(x, "")), pow(10,div(length(Integer.digits(min)),2)))]
              else
                [1 | &1] -- [1]
              end

              )
              )

              end)

          end
        end)

      end
      loop(min+1, max)
    end
  end

  def permutations([]), do: [[]]
  def permutations(list), do: for elem <- list, rest <- permutations(list--[elem]), do: [elem|rest]

end

M.hello(100000, 200000)

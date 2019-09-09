defmodule MyApp.Supervisor do
  # Automatically defines child_spec/1
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    children = [
      {Vampire1, init_arg}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Vampire1 do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(vampire1) do
    n1 = String.to_integer(List.first(vampire1))
    n2 = String.to_integer(List.last(vampire1))

    main(n1..n2)
    {:ok, vampire1}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end

  #main function
  def main(range) do
    {:ok, a_pid}=Agent.start(fn-> %{} end)
    spawn_loop(range, a_pid)

    #print O/P
    op_map=Agent.get(a_pid, fn(state)-> state end)
    Enum.each(op_map, fn({key, val})-> IO.puts "#{key} #{Enum.join(val, " ")}" end)
  end

  #loop function to create new process for each new number and check for vamp qualities
  def spawn_loop(range, a_pid), do: for i<-range, do: spawn(fn-> vamp_chk(i, a_pid) end)

  #Vampire1 checker function
  def vamp_chk(num, a_pid) do
    n_num_dig=num_dig(num, 0)

    case rem(n_num_dig, 2) do
      1->
        :discard
      0->
        r_start=pow(10, 1, trunc(n_num_dig/2)-1)
        r_end=pow(10, 1, trunc(n_num_dig/2))-1

        valid_dvsr=fn(i)-> rem(num, i)==0 and i != num and i != 1 end
        list=for x<-r_start..r_end, valid_dvsr.(x), do: x
        for x<-list, do: spawn(fn-> fang_chk(num, x, a_pid) end)
    end
  end

  #fang check function
  def fang_chk(_num, nil, _a_pid), do: :discard
  def fang_chk(num, dvsr, a_pid) do
    dvsr2=trunc(num/dvsr)
    flag = !(rem(dvsr, 10) == 0 and rem(dvsr2, 10) == 0)

    if flag do
      {:ok, num_l}=digi_extract(num, [])
      {:ok, dvsr_l}=digi_extract(dvsr, [])
      {:ok, dvsr2_l}=digi_extract(dvsr2, [])

      dvsrs_l=dvsr_l++dvsr2_l
      if num_l--dvsrs_l==[] and length(num_l)==length(dvsrs_l) do
        Agent.update(a_pid, fn(state)->
          if state[num]==nil do
            Map.put(state, num, [dvsr, dvsr2])
          else
            Map.update(state, num, state[num], &(Enum.uniq(&1++[dvsr, dvsr2])))
          end
        end)
      end
    end
  end

  #math helpers
  def num_dig(0, count), do: count
  def num_dig(num, count) do
    num_dig(trunc(num/10), count+1)
  end

  def pow(_num, res, 0), do: res
  def pow(num, res, r_to), do: pow(num, res*num, r_to-1)

  def digi_extract(0, res), do: {:ok, res}
  def digi_extract(num, res) do
    res2=List.insert_at(res, 0, rem(num, 10))
    digi_extract(trunc(num/10), res2)
  end

end

MyApp.Supervisor.start_link(System.argv())

defmodule PlusOne.Supervisor do

  use Supervisor

  def start_link(range) do
    Supervisor.start_link(__MODULE__, range, name: __MODULE__)
  end

  @impl true
  def init(range) do
    Supervisor.start_link([
      {Main_fn, range}
    ], strategy: :one_for_one)
    end

end

defmodule Main_fn do

  def main(range) do
    task_loop(range)
  end

  def task_loop(range) do
    tasks=for x<-range, do: Task.async(fn-> vamp_chk(x) end)
    res_maps=for task<-tasks, do: Task.await(task)

    #print O/P
    Enum.map(res_maps, fn({_, res})-> res end)
    #    for {num, dvsrs}<-res_maps, do: IO.puts "#{num} #{Enum.each(dvsrs, fn(x)-> x end)}"
  end

  def vamp_chk(num) do
    n_num_dig=num_dig(num, 0)

    case rem(n_num_dig, 2) do
      1->
        :discard
      0->
        r_start=pow(10, 1, trunc(n_num_dig/2)-1)
        r_end=pow(10, 1, trunc(n_num_dig/2))-1

        valid_dvsr=fn(i)-> rem(num, i)==0 and i != num and i != 1 end
        list=for x<-r_start..r_end, valid_dvsr.(x), do: x
        tasks=for x<-list, do: Task.async(fn-> fang_chk(num, x) end)
        dvsrs=for task<-tasks, do: Task.await(task)
        #        dvsrs=Enum.each(task_with_res, fn({_, {:ok, res}})-> res end)
        dvsrs=Enum.uniq(List.flatten(dvsrs))--[nil, :discard, :ok]
        if dvsrs != [] do
          %{num=>dvsrs}
        else
          %{nil=>nil}
        end
    end
  end

  def fang_chk(_num, nil), do: :discard
  def fang_chk(num, dvsr) do
    dvsr2=trunc(num/dvsr)
    flag = !(rem(dvsr, 10) == 0 and rem(dvsr2, 10) == 0)

    if flag do
      {:ok, num_l}=digi_extract(num, [])
      {:ok, dvsr_l}=digi_extract(dvsr, [])
      {:ok, dvsr2_l}=digi_extract(dvsr2, [])

      dvsrs_l=dvsr_l++dvsr2_l
      if num_l--dvsrs_l==[] and length(num_l)==length(dvsrs_l) do
        [dvsr, dvsr2]
      else
        :discard
      end
    end
  end

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

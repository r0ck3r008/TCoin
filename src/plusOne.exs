defmodule PlusOne do

  #main function
  def main(range) do
    p_pid=spawn(fn-> print_it() end)
    spawn_loop(range, p_pid)
  end

  #stateless printer server
  def print_it() do
    receive do
      msg->IO.puts(msg)
    end
    print_it()
  end

  #loop function to create new process for each new number and check for vamp qualities
  def spawn_loop(range, p_pid), do: for i<-range, do: spawn(fn-> vamp_chk(i, p_pid) end)

  #vampire checker function
  def vamp_chk(num, _p_pid) when rem(num, 100)==0, do: :discard
  def vamp_chk(num, p_pid) do
    n_num_dig=num_dig(num, 0)

    case rem(n_num_dig, 2) do
      1->
        :discard
      0->
        r_start=pow(10, 1, trunc(n_num_dig/2)-1)
        r_end=pow(10, 1, trunc(n_num_dig/2))-1

        valid_dvsr=fn(num, i)-> rem(num, i)==0 and i != num end
        for x<-r_start..r_end, valid_dvsr.(num, x), do: spawn(fn-> fang_chk(num, x, p_pid)end)
    end
  end

  #fang check function
  def fang_chk(num, dvsr, p_pid) do
    dvsr2=div(num, dvsr)
    {:ok, num_l}=digi_extract(num, [])
    {:ok, dvsr_l}=digi_extract(dvsr, [])
    {:ok, dvsr2_l}=digi_extract(dvsr2, [])

    dvsrs_l=dvsr_l++dvsr2_l
    if num_l--dvsrs_l==[] and length(num_l)==length(dvsrs_l) do
      send(p_pid, "#{num}: #{dvsr}*#{trunc(num/dvsr)}")
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

PlusOne.main(100000..200000)

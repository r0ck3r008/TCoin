defmodule Honeycomb do

  def main(n2) do
    n=get_n(n2)

    #start agent
    {:ok, agnt_pid}=Agent.start_link(fn-> %{} end)

    #start dispenser
    {:ok, disp_pid}=Honeycomb.Dispenser.start_link

    #make forbidden x and y
    frbdn=mk_frbdn(n-1, nil)

    #start workers
    for _x<-0..n2-1, do: Honeycomb.Worker.start_link(n, disp_pid, agnt_pid, frbdn)
  end

  def get_n(n2) do
    chk_sqrt(div(n2, 6), ceil(:math.sqrt(div(n2, 6))))
  end

  def chk_sqrt(n2_6, n) when rem(n2_6, n)==0, do: n
  def chk_sqrt(n2_6, n) when rem(n2_6, n)==1, do: System.halt(1)

  def mk_frbdn(t, nil) do
    mk_frbdn(
      t,
      {
        (for x<-0..(t-1), do: x)
        ++
        (for x<-(t+1)..(2*t+1), do: x),
        (for y<-0..(2*t-1), do: y)
        ++
        (for y<-(4*t+1)..(4*t+2), do: y)
      }
    )
  end
  def mk_frbdn(_t, frbdn), do: frbdn
end

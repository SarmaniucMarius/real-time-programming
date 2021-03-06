defmodule Distributor do

  def start_link(url) do
    IO.puts("Starting distributor")

    recv_pid = spawn_link(__MODULE__, :recv, [0])
    {:ok, eex_pid} = EventsourceEx.new(url, stream_to: recv_pid)
    spawn(__MODULE__, :inspect_eventsourceex, [eex_pid, url, recv_pid])
    {:ok, recv_pid}
  end

  def inspect_eventsourceex(eex_pid, url, distributor_pid) do
    Process.monitor(eex_pid)

    {:ok, new_eex_pid} = receive do
      _msg ->
        EventsourceEx.new(url, stream_to: distributor_pid)
    end

    inspect_eventsourceex(new_eex_pid, url, distributor_pid)
  end

  def recv(id) do
    id = receive do
      msg ->
        workers = Scheduler.get_workers(Scheduler)
        id = if id >= tuple_size(workers), do: 0, else: id
        worker = elem(workers, id)
        EventProcessor.process_event(worker, msg.data)

        id
    end
    recv(id+1)
  end

end

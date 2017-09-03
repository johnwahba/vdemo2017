defmodule Vdemo2017.TranscoderProducer do
  use GenStage
  defstruct [buffered_demand: 1, dir: nil, timer: nil]
  @heart_beat_timeout 10

  def start_link(dir \\ "jobs/**/*") do
    GenStage.start_link(__MODULE__, %__MODULE__{dir: dir}, name: __MODULE__)
  end

  def init(state) do
    timer = :timer.send_interval(1000, self(), :check_demand)
    {:producer, %{state | timer: timer}}
  end

  def handle_info(:check_demand, state), do: handle_demand(0, state)

  def handle_demand(demand, %__MODULE__{dir: dir, buffered_demand: buffered_demand} = transcoder)
    when demand + buffered_demand > 0 do
    total_demand = demand + buffered_demand
    {:ok, {jobs, count}} = get_jobs(dir, total_demand)
    {:noreply, jobs, %{transcoder | buffered_demand: total_demand - count}}
  end
  def handle_demand(_demand, transcoder), do: {:noreply, [], transcoder}


  defp get_jobs(dir, demand) do
    dir
    |> Path.wildcard
    |> Enum.reject(&is_meta_file?/1)
    |> Enum.reject(&locked?/1)
    |> Enum.reject(&done?/1)
    |> Enum.take(demand)
    |> Enum.map(&take_lock/1)
    |> case do
      files -> {:ok, {files, length(files)}}
    end
  end

  defp is_meta_file?(file), do: String.ends_with?(file, ".lock") || String.ends_with?(file, ".done")

  defp locked?(file) do
    file
    |> lock_file
    |> File.lstat(time: :posix)
    |> case do
      {:ok, %File.Stat{mtime: mtime}} -> mtime + @heart_beat_timeout > :os.system_time(:seconds)
      _ -> false
    end
  end

  defp done?(file) do
    file
    |> done_file
    |> File.lstat(time: :posix)
    |> case do
      {:error, :enoent} -> false
      _ -> true
    end
  end

  defp lock_file(file), do: "#{file}.lock"
  defp done_file(file), do: "#{file}.done"

  defp take_lock(file) do
    with lock <- lock_file(file), :ok <- File.touch!(lock) do
      {file, lock}
    end
  end
end

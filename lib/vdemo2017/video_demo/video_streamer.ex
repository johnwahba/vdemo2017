defmodule FileFetcher do
  use GenStage

  def start_link(files), do: GenStage.start_link(FileFetcher, files)

  def init(files), do: {:producer, files}

  def handle_demand(demand, files) do
    {files, remainder} = Enum.split(files, demand)
    {:noreply, files, remainder}
  end
end

defmodule FileReader do
  use GenStage

  def start_link(), do: GenStage.start_link(__MODULE__, :ok)
  def init(thing), do: {:producer_consumer, thing}
  def handle_events(files, _from, :ok) do
    {:noreply, Enum.flat_map(files, &stream_file/1), :ok}
  end
  def stream_file(file) do
    File.stream!(file, [read_ahead: 188 * 4_000], 188 * 1_000)
  end
end

defmodule FilterApplier do
  use GenStage

  def start_link(), do: GenStage.start_link(__MODULE__, :ok)
  def init(thing), do: {:producer_consumer, thing}
  def handle_events(streams, _from, :ok) do
    resp = apply_filter(streams)
    {:noreply, [resp], :ok}
  end
  def apply_filter(bytes) do
    opts = [in: bytes, out: :stream]
    %{"yay" => yays, "nay" => nays} = Vdemo2017.Voter.get_results()
    %{out: out} = Porcelain.spawn("ffmpeg", [
      "-i", "-",
      "-f", "mpegts",
      "-b", "12000k",
      "-acodec", "copy",
      "-vf", "drawtext='fontfile=/Library/Fonts/Arial\ Bold.ttf: \
            text=\'yays-#{yays} nays-#{nays} time-#{:os.system_time(:seconds)}\': \
            fontcolor=white: fontsize=72: box=1: boxcolor=black@0.5: \
            boxborderw=5: x=(w-text_w)/2: y=(h-text_h)'",
      "-"], opts)
    out
  end
end

defmodule Vdemo2017.VideoStreamer do
  use GenServer
  def start_link(dir \\ "transcode/**/*.ts") do
    GenServer.start_link(__MODULE__, Path.wildcard(dir), name: __MODULE__)
  end
  def init(dir) do
    {:ok, dir}
  end

  def start() do
    GenServer.call(__MODULE__, :start)
  end

  def handle_call(:start, _from, dir) do
    start_stream(dir)
    {:reply, :ok, dir}
  end

  def start_stream(dir) do
    with {:ok, file_fetcher} <- FileFetcher.start_link(dir),
      {:ok, file_reader} <- FileReader.start_link(),
      {:ok, filter_applier} <- FilterApplier.start_link(),
      stream <- GenStage.stream([{filter_applier, min_demand: 0, max_demand: 1}]) do
        GenStage.sync_subscribe(file_reader, to: file_fetcher, min_demand: 0, max_demand: 1)
        GenStage.sync_subscribe(filter_applier, to: file_reader, min_demand: 10, max_demand: 20)
        stream
        |> Stream.flat_map(&(&1))
        |> play()
    end
  end


  def blocking_start_stream(dir) do
    dir
    |> Stream.flat_map(&read_file/1)
    |> Stream.chunk_every(10000)
    |> Stream.flat_map(&apply_filter/1)
    |> play
  end

  def read_file(file) do
    File.stream!(file, [read_ahead: 188 * 2_000], 188 * 1_000)
  end

  def apply_filter(bytes) do
    opts = [in: bytes, out: :stream]
    %{"yay" => yays, "nay" => nays} = Vdemo2017.Voter.get_results()
    %{out: out} = Porcelain.spawn("ffmpeg", [
      "-i", "-",
      "-f", "mpegts",
      "-b", "12000k",
      "-acodec", "copy",
      "-vf", "drawtext='fontfile=/Library/Fonts/Arial\ Bold.ttf: \
            text=\'yays-#{yays} nays-#{nays} time-#{:os.system_time(:seconds)}\': \
            fontcolor=white: fontsize=72: box=1: boxcolor=black@0.5: \
            boxborderw=5: x=(w-text_w)/2: y=(h-text_h)'",
      "-"], opts)
    out
  end

  def play(bytes) do
    opts = [in: bytes]
    Porcelain.spawn_shell("ffmpeg -i - -acodec copy -f mpegts -b 12000k  - | ffplay - -x 1080 -y 720", opts)
  end
end

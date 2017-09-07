defmodule Vdemo2017.VideoStreamer do
  use GenServer
  def start_link(dir \\ "chunk/**/*.ts") do
    GenServer.start_link(__MODULE__, Path.wildcard(dir), name: __MODULE__)
  end
  def init(dir) do
    {:ok, dir}
  end

  def start() do
    GenServer.call(__MODULE__, :start)
  end

  def handle_call(:start, _from, dir) do
    blocking_start_stream(dir)
    {:reply, :ok, dir}
  end

  def start_stream(dir) do
    dir
    |> Stream.map(&read_bytes/1)
    |> Task.async_stream(&apply_filter/1, concurrency: 1, ordered: true, timeout: 5_000_000)
    |> Stream.flat_map(fn({:ok, bytes}) -> bytes end)
    |> play
  end

  def blocking_start_stream(dir) do
    dir
    |> Stream.map(&read_bytes/1)
    |> Stream.flat_map(&apply_filter/1)
    |> play
  end

  def read_bytes(file) do
    file
    |> File.read!()
    |> List.wrap()
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

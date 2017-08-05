defmodule Vdemo2017.VideoStreamer do
  def start_link(dir \\ "media/*") do
    GenServer.start_link(__MODULE__, Path.wildcard(dir))
  end
  def init(dir) do
    dir
    |> Enum.flat_map(&read_bytes/1)
    |> play
    {:ok, dir}
  end

  def read_bytes(file) do
    file
    |> File.read!()
    |> List.wrap()
  end

  def play(bytes) do
    opts = [in: bytes, err: IO.stream(:stderr, :line)]
    Porcelain.spawn_shell("ffmpeg -i - -f mpegts -b 12000k  - | ffplay -", opts)
  end
end

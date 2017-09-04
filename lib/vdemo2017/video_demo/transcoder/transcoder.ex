defmodule Vdemo2017.Transcoder do
  use Task
  @heartbeat 5_000

  def start_link({file, lock}) do
    Task.start_link(fn ->
      keep_lock_while_alive(self(), lock, @heartbeat)
      file
      |> transcode()
      |> chunk()
      done({file, lock})
    end)
  end

  def transcode(file) do
    transcode_path = transcode_path(file)
    :filelib.ensure_dir(transcode_path)
    %{status: 0} = Porcelain.exec("ffmpeg", [
      "-i", file,
      "-vcodec", "libx264",
      "-x264opts", "keyint=30:min-keyint=30:scenecut=-1",
      "-acodec", "copy",
      transcode_path], err: :out)
    transcode_path
  end

  def chunk(file) do
    chunk_path = chunk_path(file)
    :filelib.ensure_dir(chunk_path)
    %{status: 0} = Porcelain.exec("ffmpeg", [
      "-i", file,
      "-c", "copy",
      "-map", "0",
      "-f", "segment",
      "-segment_time", "1",
      "-vcodec", "copy",
      chunk_path])
    chunk_path
  end

  def transcode_path(file), do: "transcode/#{file}.ts"
  def chunk_path(transcode_path), do: "chunk/#{String.slice(transcode_path, 0..-4)}/%04d.ts"

  def done({file, lock}) do
    File.rm!(lock)
    File.touch!("#{file}.done")
  end

  def keep_lock_while_alive(pid, lock, heartbeat) do
    if Process.alive?(pid) do
      :ok = File.touch!(lock)
      :timer.apply_after(heartbeat, __MODULE__, :keep_lock_while_alive, [pid, lock, heartbeat])
    end
  end
end

defmodule ExDockerLogs.LogEntry do
  @moduledoc """
    The struct returned by stream_logs
  """

  @type t ::%__MODULE__{
    container_id: String.t,
    message: String.t,
    stream_type: String.t
  }
  defstruct [:container_id, :message, :stream_type]
end

defmodule ExDockerLogs.ContainerLogs do
  require Logger

  @default_opts [
    details: false,
    follow: true,
    stdout: true,
    stderr: true,
    since: 0,
    timestamps: 0,
    tail: 0
  ]

  @moduledoc """
    Fetch logs from the docker API and return a Stream
  """

  @doc """
    Create a stream and return the first 42 log entries:

    s = ExDockerLogs.ContainerLogs.stream_logs(container_id, [timestamps: true])

    Enum.take(s, 42)

  """

  def stream_logs(container_id, opts \\ []) do
    Stream.resource((fn -> start_stream(container_id, process_opts(opts)) end),
                    &next/1,
                    &terminate_stream(&1))
  end

  defp start_stream(container_id, opts) do
    {:ok, %HTTPoison.AsyncResponse{id: id}} = HTTPoison.get(
      build_url(container_id),
      %{},
      stream_to: self(),
      timeout: :infinity,
      recv_timeout: :infinity,
      params: opts)
    {id, container_id}
  end

  def next({stream_id, container_id}) do
    receive do
      %HTTPoison.AsyncStatus{ id: ^stream_id, code: 200 } ->
        Logger.debug "Received code 200, starting stream"
        {[], {stream_id, container_id}}
      %HTTPoison.AsyncStatus{ id: ^stream_id, code: code} ->
        raise "Received code #{code}"
      %HTTPoison.AsyncChunk{id: ^stream_id, chunk: chk} ->
        case chk do
          <<stream_type::8, 0, 0, 0, _size::32,data::binary >> ->
            {
              [handle_chunck(stream_type, data, container_id)],
              {stream_id, container_id}
            }
        end
      %HTTPoison.AsyncEnd{id: ^stream_id} ->
        Logger.debug "Stream ended"
        {:halt, {stream_id, container_id}}
      %HTTPoison.Error{id: ^stream_id, reason: reason} ->
        raise "Stream error #{reason}"
      _ -> {[], {stream_id, container_id}}
    end
  end

  defp terminate_stream({stream_id, _container_id}) do
    Logger.debug "terminating stream"
    {:ok, _} = :hackney.stop_async(stream_id)
    Logger.debug "stream terminated"
  end

  defp handle_chunck(stream_type, data, container_id) do
    %ExDockerLogs.LogEntry{
      container_id: container_id,
      message: data,
      stream_type: case stream_type do
        0 -> "stdin"
        1 -> "stdout"
        2 -> "stderr"
      end
    }
  end

  defp build_url(container_id) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock"
    url <> "/containers/#{container_id}/logs"
  end

  defp process_opts(opts) do
    @default_opts
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end
end

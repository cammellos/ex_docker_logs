defmodule ExDockerLogs.ContainerLogs do
  require Logger

  def stream_logs(container_id) do
    Stream.resource((fn -> initialize_stream(container_id) end), &handle_chunck/1, &close_stream/1)
  end

  defp initialize_stream(container_id) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock"
    {:ok, %HTTPoison.AsyncResponse{id: id}} = HTTPoison.get url <> "/containers/#{container_id}/logs?stderr=1&stdout=1&timestamps=1&tail=50", %{}, stream_to: self, timeout: :infinity
    {id, []}
  end

  def handle_chunck({stream_id, acc}) do
    IO.inspect stream_id
    IO.inspect acc
    IO.inspect "Called"
    receive do
      %HTTPoison.AsyncStatus{ id: stream_id, code: 200 } ->
          IO.inspect "Status"
          {[], {stream_id, acc}}
      %HTTPoison.AsyncStatus{ id: stream_id, code: code} ->
        Logger.info "Received code #{code}, stopping"
        {[], {stream_id, acc}}
      %HTTPoison.AsyncHeaders{headers: headers, id: stream_id} ->
         IO.inspect headers
         {acc, {stream_id, acc}}
      %HTTPoison.AsyncChunk{id: stream_id, chunk: chk} ->
        Logger.info "Received chunck #{chk}"
        case chk do
          <<stream_type::8, 0, 0, 0, size::32,rest::binary >> -> {[rest|acc], {stream_id, [rest|acc]}}
          _ -> {acc, {stream_id, acc}}
        end
      %HTTPoison.AsyncEnd{id: stream_id} ->
        Logger.info "Stream ended"
        {:halt, {stream_id, acc}}
      %HTTPoison.Error{id: stream_id, reason: reason} ->
        Logger.info "Stream error #{reason}"
        {[], {stream_id, acc}}
      anything ->
        Logger.log "Should not be here"
        IO.inspect anything
    end
  end

  defp close_stream(stream) do
    IO.inspect stream
    IO.inspect "Closing"
  end
end


defmodule ExDockerLogsTest do
  use ExUnit.Case, async: true
  require Logger
  doctest ExDockerLogs


  setup_all do
    Logger.debug "Setting up tests"

    image_name = "ex_docker_logs"

    {:ok, %{status_code: 200}} = IO.inspect(build_image(image_name))
    {:ok, container_id} = create_container(image_name)
    {:ok, _body} = start_container(container_id)

    on_exit("clean_up_image_#{image_name}_#{container_id}", fn ->
      Logger.debug "Cleanup tests"
      IO.inspect("Deleting image #{image_name} and #{container_id}")
      stop_container(container_id)
      delete_container(container_id)
      delete_image(image_name)
    end)

    {:ok, [image_name: image_name, container_id: container_id]}
  end

  test "the log format", context do
    cid = context[:container_id]
    stream = ExDockerLogs.ContainerLogs.stream_logs(cid)
    entries = Enum.take(stream, 1)

    assert Enum.count(entries) == 1

    first_entry = List.first(entries)

    assert first_entry.container_id == cid
    assert Integer.parse(first_entry.message)
  end

  test "the order of entries", context do
    cid = context[:container_id]
    stream = ExDockerLogs.ContainerLogs.stream_logs(cid)
    entries = Enum.take(stream, 5)

    assert Enum.count(entries) == 5

    messages = Enum.map(entries, &(String.strip(&1.message)))

    {start, _} = Integer.parse(List.first(entries).message)

    start..start+4
    |> Stream.with_index
    |> Enum.each(fn({entry, i}) ->
      assert Integer.to_string(entry) == Enum.at(messages, i)
    end)


  end

  defp delete_image(name) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/images/#{name}?force=true"
    {:ok, %{status_code: 200}} = HTTPoison.delete url, [], timeout: 50000, recv_timeout: 50000
  end

  defp build_image(name) do
    {:ok, tar_file} = File.read("./test/resources/dockerfile.tar.gz")
    url = "http+unix://%2fvar%2frun%2fdocker.sock/build?t=#{name}"
    Logger.debug("Hitting #{url}")
    HTTPoison.post url, tar_file
  end

  defp delete_container(id) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/containers/#{id}?force=true"
    {:ok, %{status_code: 204}} = HTTPoison.delete url, [], timeout: 50000, recv_timeout: 50000
  end

  defp create_container(name) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/containers/create"
    {:ok, %{body: body}} = HTTPoison.post url, Poison.Encoder.encode(%{"Image": name}, []),  [{"Content-Type", "application/json"}]
    {:ok, Map.get(Poison.Parser.parse!(body), "Id")}
  end

  defp start_container(id) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/containers/#{id}/start"
    {:ok, %{status_code: 204}} = HTTPoison.post url, ""
  end

  defp stop_container(id) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/containers/#{id}/stop"
    Logger.debug "Stopping container #{id}"
    {:ok, %{status_code: status_code}} = HTTPoison.post(url, "", [], timeout: 50000, recv_timeout: 50000)
    Logger.debug "Stopped container #{id} with status #{status_code}"
    if status_code in [204, 304] do
      {:ok, status_code}
    else
      {:err, status_code}
    end
  end

end

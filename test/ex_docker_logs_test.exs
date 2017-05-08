defmodule ExDockerLogsTest do
  use ExUnit.Case
  doctest ExDockerLogs

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  defp delete_image(name) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/images/#{name}"
    {:ok, %{status_code: 200}} = HTTPoison.delete url
  end

  defp build_image(name) do
    {:ok, tar_file} = File.read("./test/resources/dockerfile.tar.gz")
    url = "http+unix://%2fvar%2frun%2fdocker.sock/build?t=#{name}"
    HTTPoison.post url, tar_file
  end

  defp delete_container(id) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/containers/#{id}"
    {:ok, %{status_code: 204}} = HTTPoison.delete url
  end

  defp create_container(name) do
    url = "http+unix://%2fvar%2frun%2fdocker.sock/containers/create"
    {:ok, %{body: body}} = HTTPoison.post url, Poison.Encoder.encode(%{"Image": name}, []),  [{"Content-Type", "application/json"}]
    {:ok, Map.get(Poison.Parser.parse!(body), "Id")}
  end

  setup_all do
    image_name = "ex_docker_logs"

    {:ok, %{status_code: 200}} = build_image(image_name)
    {:ok, container_id} = create_container(image_name)

    on_exit("clean_up_image", fn ->
      delete_image(image_name)
      delete_container(container_id)
    end)


    {:ok, [image_name: image_name]}
  end

  test "the truth" do
    assert 1 + 1 == 2
  end
end

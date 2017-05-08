defmodule ExDockerLogs.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_docker_logs,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()]
  end

  def application do
    [applications: [:httpoison, :poison],
      extra_applications: [:logger]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.11.1"},
      {:poison, "~> 3.0"},
      {:dogma, "~> 0.1", only: :dev},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false}
    ]
  end
end

# ExDockerLogs

A simple library to read logs as a Stream from a docker container

## Example usage

```
stream = ExDockerLogs.ContainerLogs.stream_logs("b4b29039b1b2", tail: 50)
```

Will return a stream.

You can set the following options:

`follow`: defaults to `true`

`details`: defaults to `false`

`stdout`: defaults to `true`

`stderr`: defaults to `true`

`since`: defaults to `0`

`timestamps`: defaults to `0`

`tail`: defaults to `all`

See the docker API for reference

```
entry = Enum.take(stream, 1)
```

Entry is a struct:

```
%ExDockerLogs.LogEntry{
  container_id: "b4b29039b1b2",
  message: "some text",
  stream_type: "stdout"}
```

Stream types are `stdout`, `stdin` and `stderr`

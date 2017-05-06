# ExDockerLogs

A simple library to read logs as a Stream from a docker container

## Example usage

```
stream = ExDockerLogs.ContainerLogs.stream_logs("b4b29039b1b2")
```

Will return a stream.

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

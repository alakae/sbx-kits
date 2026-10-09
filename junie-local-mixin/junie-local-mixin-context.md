## Junie Local

Junie is installed and wired to the local inference engine on the host at
http://host.docker.internal:19239. Start it with `junie-local`, which runs
`junie --model custom:local-qwen3.6-27b-4bit`. Requests to the engine are
authenticated by the sandbox proxy; no token is needed inside the sandbox.

## Sandbox environment

You are running inside a Docker sandbox. All model calls are routed to a local
Ollama instance on the host (http://host.docker.internal:11434); this kit
grants no Anthropic host. The workspace is mounted at its absolute host path.
`sudo` is passwordless; use it for package installs.

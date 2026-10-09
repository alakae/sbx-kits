## Sandbox environment

You are running inside a Docker sandbox. The only reachable host is the
local inference engine at http://host.docker.internal:19239 — no cloud LLM
provider, package registry, or git forge is reachable. Do not suggest
commands that require network access. The workspace is mounted at its
absolute host path.

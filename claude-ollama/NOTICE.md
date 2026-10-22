Based on [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib/tree/41e088ce786d7ac71ad0b4e4dd025c436a9a4e00/claude-ollama) (Apache-2.0).

Forked back from upstream: the kit was originally contributed to docker/sbx-kits-contrib from this repository, and this copy carries every upstream change as of that commit.

Modified for alakae/sbx-kits:

- claude-ollama.yaml: the allow entry is `localhost:11434` instead of `host.docker.internal:11434`. The sandbox proxy rewrites `host.docker.internal` to `localhost` before matching, so upstream's entry never matches and no request reaches Ollama (verified with sbx v0.49.1 on a KVM host).
- claude-ollama-context.md: says the kit grants no Anthropic host, instead of claiming Anthropic is unreachable (the global sbx policy can still allow it).
- README.md: usage uses the alakae/sbx-kits git URL and a local path; documents the host rewrite, `-e CLAUDE_OLLAMA_MODEL=…`, and that endpoint-only egress needs a `deny-all` global policy; drops the Linux `--add-host` note and the pointer to the mixin, which this repository does not carry.

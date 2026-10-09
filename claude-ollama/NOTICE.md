Based on [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib/tree/7f8518ce98d439a35096ff7f6d00e9b8f65b0f53/claude-ollama) (Apache-2.0).

Forked back from upstream: the kit was originally contributed to docker/sbx-kits-contrib from this repository, and this copy carries every upstream change as of that commit.

Modified for alakae/sbx-kits:

- README.md: usage points at alakae/sbx-kits (git URL and local clone) instead of the docker.io/docker/sbx-kit-claude-ollama image and the contrib git URL; the note on requires-claude mixins names this repo's claude-safe-mixin and contrib's claude mixins.
- claude-ollama.yaml: two comments that described kits in contrib now name docker/sbx-kits-contrib explicitly (and this repo's claude-safe).

# Manual checks for the v3 migration

These checks need a real sandbox, so they couldn't run during the migration.
Run them on your Mac with `sbx` v0.45.0 or newer, from a clone of this repo on
the `v3` branch.

## 0. Prerequisite: containerd image store

- [ ] Docker Desktop → Settings → General → "Use containerd for pulling and
  storing images" is on (Apply & restart). Without it, every local kit build
  fails with "OCI exporter is not supported for the docker driver". Images
  from the old store are hidden (not deleted) after switching.

## 1. Local-model address (most likely to fail)

`claude-ollama` and `junie-local` (and their mixins) now allow
`host.docker.internal:PORT` (contrib's form) instead of the old
`localhost:PORT`. With Ollama and Junie Local running on the host:

```console
$ sbx run ./claude-ollama .
$ sbx run ./junie-local .          # needs: sbx secret set junie-local
$ sbx policy log <sandbox>
```

- [ ] Ollama answers a prompt.
- [ ] Junie answers "say hi".
- [ ] If either request shows up as blocked in the policy log: switch the
  allow-list entry (and junie-local's credential inject domain) back to
  `localhost:PORT` in `claude-ollama`, `claude-ollama-mixin`, `junie-local`
  and `junie-local-mixin`.

## 2. claude-safe

```console
$ sbx run ./claude-safe --kit ./base-rules --kit ./base-skills .
```

- [ ] Shift+Tab offers neither bypass nor auto.
- [ ] Remote Control does not auto-connect (couldn't be tested without a login).
- [ ] The workspace gets `.claude/rules/` and `.claude/skills/` with the
  kits' files, and `git status` stays clean (the shipped `.gitignore` files
  hide them).
- [ ] The rules (`/memory`) and skills show up in the session. Startup hooks
  run in the background, so on the very first session they may only appear
  after restarting the agent; note whether that happens.
- [ ] API-key login and subscription login both work.

## 3. claude-safe-mixin on contrib's `claude`

```console
$ sbx run "git+https://github.com/docker/sbx-kits-contrib.git#ref=7f8518ce98d439a35096ff7f6d00e9b8f65b0f53&dir=claude" \
    --kit ./claude-safe-mixin .
```

- [ ] The session starts in prompting mode, even though that workload
  launches with `--dangerously-skip-permissions`.

## 4. Per-mixin checks

A bare built-in agent name (e.g. `shell`) selects `sbx`'s legacy v2 kit, which
can't combine with any v3 `--kit` mixin. Use a real v3 workload in the
positional slot instead — Docker's published
`docker.io/docker/sbx-kit-shell:1.0.0` below:

- [ ] nix: `sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./nix .`, then
  `nix-shell -p hello --run hello` works, also from the agent's
  non-interactive shell.
- [ ] devbox: `sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./nix --kit ./devbox .`,
  then `devbox.json` appears in the workspace after boot, and
  `devbox run -- node --version` works after `devbox add nodejs`.
- [x] ruff-lint: `sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./ruff-lint .`,
  then `ruff --version` reports the pinned default (`0.8.4`), `ruff check`
  uses `~/.config/ruff/ruff.toml` in a repo without its own config, and
  `~/.config/ruff` is owned by `agent`.
- [ ] cloudscale-api: `sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./cloudscale-api .`,
  then `curl https://api.cloudscale.ch/v1/servers` is authenticated
  (needs `sbx secret set cloudscale`).
- [ ] junie-local-mixin: `sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./junie-local-mixin .`,
  then `junie-local` answers.

## 5. nix and ruff-lint no longer need a Debian base

`nix` and `ruff-lint` used to run their install (`apt-get`, `uv tool install`)
at sandbox creation, which is why `nix` declared `requires: ["deb/apt"]` and
could only compose onto a Debian/Ubuntu-based workload. Both now build their
tool in their own Dockerfile build stage and ship only the result (a `/nix`
store; a standalone `ruff` binary), so neither needs apt, uv, or any
particular base at all.

- [ ] `sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./nix .` composes
  without a `deb/apt`-related error (confirms the `requires` entry is really
  gone, not just satisfied).
- [ ] If a non-Debian v3 workload is available to test with, `--kit ./nix`
  and `--kit ./ruff-lint` compose onto it too — this is the actual
  portability win from the rework, not just re-pointing at a Debian shell.

## 6. Egress under deny-all

```console
$ sbx policy init deny-all
```

- [ ] Re-run the checks above; `sbx policy log` shows no blocked hosts.

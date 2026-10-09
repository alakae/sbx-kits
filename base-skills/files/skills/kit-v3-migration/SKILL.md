---
name: kit-v3-migration
description: Migrate Docker Sandboxes kits from the v1/v2 spec.yaml format to kit spec v3 (<kit>/<kit>.yaml with `# syntax=docker/sandbox-kit:3`). Use when a repo still has spec.yaml kits, when asked to port, upgrade or convert kits to v3, or when a v3 kit build or composition fails during such a migration.
---

# Migrate kits to spec v3

## Check the ground first

- `sbx version` must be **v0.45.0 or newer**. Stable releases load v3 from
  there on; notes saying "needs an RC/nightly" are outdated. v3 kits cannot be
  composed with v1/v2 kits, so migrate a collection as a whole.
- **Bare built-in agent names are always v2.** `sbx run shell --kit
  ./some-v3-mixin` fails incoherently ("no workload kit in the set") no
  matter how fully a collection is migrated — `shell`, `claude`, `codex`, and
  every other built-in name passed positionally select `sbx`'s v2 kit for
  that agent, which can never combine with a v3 `--kit`. The positional slot
  needs an actual v3 workload: a local/published one of your own, or Docker's
  published stand-ins (`docker.io/docker/sbx-kit-shell:1.0.0` for a bare
  shell, `docker/sbx-kit-<agent>-mixin` layered onto it for an agent).
- **`sbx kit validate` cannot check v3 source kits** ("no kit builder
  configured"). The build is the validation:
  `cd <kit> && docker buildx build . -f <kit>.yaml --output type=cacheonly`.
  Decoding is strict, so a leftover v1/v2 key fails the build.
- Kit builds need Docker's **containerd image store**. On Docker Desktop:
  Settings → General → "Use containerd for pulling and storing images".
  Otherwise: "OCI exporter is not supported for the docker driver".
- `sbx kit inspect ./<kit>` needs a running sbx daemon (not available inside
  a sandbox). A real run (`sbx run`) is the only proof that hooks and egress
  work; list those checks for the user rather than claiming them.
- Worked v3 examples: docker/sbx-kits-contrib, `v3` branch (its README and
  CONTRIBUTING "Migrating a kit to v3"). Its `skills/kit-author` and
  docs.docker.com kit pages still describe v2. Ignore its
  `migrate-v1-to-v2.go`.

## Layout

```text
<kit>/<kit>.yaml         first line: # syntax=docker/sandbox-kit:3, schemaVersion: "3"
<kit>/<kit>.dockerfile   recipe, paired by filename stem (required for a workload)
<kit>/<kit>-context.md   agent-context body
<kit>/files/             assets the recipe COPYs
```

No `spec.yaml`, no plain `Dockerfile`, no `files/` convention, no
`testdata/tck.yaml`. The build context cannot leave the kit directory, so a
workload and its mixin each carry their own copy of shared files. On a
case-insensitive filesystem, check that `git mv Dockerfile <kit>.dockerfile`
did not leave a stray `dockerfile` behind.

## Field mapping

| v1 / v2 | v3 |
|---|---|
| `name:` | dropped; add `version:` (and `provides:` if others depend on it) |
| `kind: sandbox` / `kind: agent` | `kind: workload` (must have a recipe) + `sbx@1` capability |
| `sandbox.image` / `agent.image` | recipe `FROM` |
| `entrypoint` / `entrypoint.run` | recipe `ENTRYPOINT` (this also clears the base's inherited `CMD`) |
| `environment.variables` | workload: recipe `ENV`; mixin: see below |
| `permissions.network` / `network.allowedDomains` | `network-policy@1` with `install:` and `runtime:` lists |
| `credentials[]` / `credentials.sources` + `serviceDomains`/`serviceAuth` | one `credential@1` per service (`apiKey.inject[]`) |
| `setup.install` / `commands.install` | `lifecycle@1.install` |
| `setup.startup` | `lifecycle@1.startup` |
| `setup.files` / `initFiles` | `lifecycle@1.files` (`onlyIfMissing: true` → `overwrite: false`) |
| `agentInstructions` / `memory` / `aiFilename` | `agent-context@1` (`filename:` only on workloads) |
| `requires: {agent: x}` | `requires: ["x"]`, plus real deps such as `deb/apt`, `deb/jq` |
| `files/home/...`, `files/workspace/...` | see below |

## Judgment calls

- **Keep it simple, with one exception.** Keep the existing install commands
  as lifecycle hooks and add only what v3 requires; do not add version pins
  or checksums unless asked. The exception: if the install hook needs a
  `requires:` entry to run at all (typically `deb/apt`, because the hook
  itself calls `apt-get`), that makes the mixin refuse every workload that
  isn't Debian-based — including the common case of composing onto a bare
  shell. Prefer moving that install into the mixin's own Dockerfile build
  stage instead (its own `FROM debian:...`, unrelated to whatever workload
  it ends up composed onto), copying only the result into a `scratch` final
  stage — see docs.docker.com's "Build a tool mixin" / "Leave build tools out
  of the mixin". This drops the `requires` entry entirely and is usually
  worth the extra work for exactly that reason. It doesn't apply to tools
  that distribute a self-updating launcher shim rather than a real binary
  (Jetify's `devbox` installer does this) — baking the shim into an image
  buys nothing, since it still fetches the real binary over the network on
  first run regardless of install method; leave those as runtime install
  hooks.
- **Network phases.** An absent phase grants nothing. Hosts reached by
  install hooks go in `install`; by the agent or by startup hooks in
  `runtime`; both if both. Installers often fetch more than their URL (for
  example Nix runs `nix-channel --update`). `apt-get update` needs every
  configured source: `archive.ubuntu.com`, `security.ubuntu.com`,
  `ports.ubuntu.com`, and `download.docker.com` on `*-docker` templates.
  Write hosts portless, except `host.docker.internal:PORT`.
- **Hook environment is deny-by-default.** List every variable a hook (or its
  children) reads in `env:`, e.g. `[HTTP_PROXY, HTTPS_PROXY]` for anything
  that downloads, `WORKSPACE_DIR` for workspace work. `USER` is not set.
- **Credentials** are required unless `optional: true`; v2 defaulted to
  optional, so add it unless the old spec said `required: true`. Each
  `inject[].domain` must exactly match a host in the same phase's allow list.
- **Mixin environment.** A mixin's image config never reaches the composed
  image, so `ENV` in a mixin recipe does nothing. Use
  `/etc/profile.d/<kit>-env.sh` for login shells, or an idempotent install
  hook appending to `/etc/sandbox-persistent.sh` for non-interactive ones
  (`grep -qxF '<line>' f || echo '<line>' >> f`; hooks can rerun).
- **Overlay ownership.** `COPY --chown=1000:1000` also chowns the parent
  directories it creates, handing `/home` to the agent. Stage under `/out` in
  a build stage, `chown -R 1000:1000 /out/home/agent`, then
  `FROM scratch` + `COPY --from=build /out /`. Root-owned paths outside the
  home (`/usr/local/...`, `/etc/...`) can use a plain `COPY`.
- **Never `COPY` a whole home directory.** If a build stage creates its user
  with `useradd --create-home`, that user's home now also contains the
  base image's default skeleton dotfiles (`.bashrc`, `.profile`,
  `.bash_logout`) — files that belong to whatever real workload this mixin
  gets composed onto, not to this mixin. A wholesale
  `COPY --from=build /home/agent /home/agent` ships them anyway, silently
  overwriting the composed workload's own versions (this broke a live
  sandbox's startup in practice — the symptom was a generic "failed to run
  sandbox container", not an obvious dotfile error). List the exact paths an
  installer created (check with `find /home/agent -mindepth 1` in the build
  stage) and `COPY` each one individually instead of the directory.
- **Workspace files** (old `files/workspace/`): either move them to user
  level (`~/.claude/rules`, `~/.config/<tool>/`) or copy them in a startup
  hook with `set -eu` and `cd "$WORKSPACE_DIR"`. Install hooks may run before
  the workspace is mounted.
- **Skills.** sbx mounts its shared skills store over `~/.claude/skills`
  (read-only by default), hiding anything baked there. Stage skills
  elsewhere and copy them in an install hook that first probes writability.
- **Claude Code policy.** To enforce settings no flag can override, ship a
  managed-settings drop-in at `/etc/claude-code/managed-settings.d/<name>.json`
  (for example `permissions.disableBypassPermissionsMode: "disable"`).
- **Attribution.** Content copied from docker/sbx-kits-contrib is Apache-2.0:
  add a verbatim `LICENSE-APACHE` and a `NOTICE.md` pinned to the commit SHA
  listing what you changed, and point usage examples at the target repo.

Mark every deliberate behaviour change with a `# MIGRATION NOTE:` comment in
the descriptor.

## Workflow

1. Inventory every kit: current version, kind, every stanza, files, recipe.
2. Migrate one kit (or workload + `-mixin` pair) per commit; delete the old
   files in the same commit.
3. Per kit: build with `--output type=cacheonly`, `yamllint` the descriptor,
   shellcheck any scripts. For overlays, export with
   `--output type=tar,dest=x.tar` and check `tar tvf` for paths and
   ownership; to smoke-test, `ADD x.tar /` onto a base image and run the tool.
4. Update CI kit discovery from `*/spec.yaml` to `<dir>/<dir>.yaml` and use
   the build as the validation step.
5. Update READMEs: a workload goes first in `sbx run`, mixins via `--kit`;
   local paths must be explicit (`./kit`).
6. Hand the user a checklist of real-sandbox runs, including
   `sbx policy log` under `sbx policy init deny-all`.

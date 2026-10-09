# nix

A mixin that installs [Nix](https://nixos.org/) in single-user mode, making
`nix-shell` available to the agent. Base for layered Nix kits.

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit "git+https://github.com/alakae/sbx-kits.git#dir=nix"
```

Stack with other mixins using multiple `--kit` flags. Nix is built once, at
publish time, in `nix.dockerfile`'s own build stage — the composed workload
doesn't need apt/deb or any particular base at all, only `/nix` and a few
files under `/home/agent` copied in from that stage.

## What it adds

- `nix-shell` (and the rest of the Nix CLI) on `PATH`, activated by sourcing
  `nix.sh` from `/etc/sandbox-persistent.sh` — the sbx mechanism sourced via
  `BASH_ENV` in every non-interactive shell (including the agent's Bash tool)
- `nixpkgs` channel available for package resolution
- Binary cache (`cache.nixos.org`) allowed through the network policy
- `export USER=agent` written to `/etc/sandbox-persistent.sh` — required
  because `nix.sh` silently skips PATH exports if `$USER` is unset, and sbx
  does not set it automatically

Note: the Nix installer only writes its PATH setup to `~/.profile` or
`~/.bash_profile` if one already exists. Neither exists in the agent home, so
the kit writes the sourcing line to `/etc/sandbox-persistent.sh` directly
instead of relying on the installer's shell-detection logic.

## Verify

```console
$ docker buildx build ./nix -f ./nix/nix.yaml --output type=cacheonly
$ sbx kit inspect  ./nix
```

Smoke test inside the sandbox:

```console
$ nix-shell -p hello --run hello
Hello, World!
```

Want Node 24 without installing Node 24?

```bash
nix-shell -p nodejs_24
```

You're now in a shell where `node --version` works. 

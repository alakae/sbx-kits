> [!NOTE]
> <strong>Experimental: Sandbox Kit v3</strong>
>
> This kit uses the experimental [Sandbox Kit specification](https://github.com/docker/sandbox-kit-spec), specifically [v3](https://github.com/docker/sandbox-kit-spec/blob/main/docs/spec/SPEC-v3.md). The format and runtime behavior may change before v3 is stable.

# sbx — Docker Sandboxes

A mixin kit that installs the whole [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) release (`sbx`): the CLI and its runtime components, from the pinned [docker/sbx-releases](https://github.com/docker/sbx-releases) tarball. Pairs with any v3 workload. Inside an sbx sandbox it is useful for client-side work such as `sbx kit inspect` while authoring kits; the runtime parts need `/dev/kvm` (see [Limitations](#limitations)).

## Usage

```console
sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
  --kit "git+https://github.com/alakae/sbx-kits.git#dir=sbx" \
  .
```

From a local clone, point `--kit` at `./sbx` instead.

Pick a different release with `--kit-arg sbx.version=<x.y.z>` (default `0.51.0`).

### Signing in

Some commands refuse while signed out. Sign in with a Docker personal access token (create one at `https://app.docker.com/accounts/<docker-id>/settings/personal-access-tokens`), inside the sandbox. `read -s` asks for the PAT without echoing it or putting it in the shell history:

```console
DOCKER_ID=<docker-id>
read -rsp 'Docker PAT: ' PAT; echo
printf '%s' "$PAT" | sbx login --username "$DOCKER_ID" --password-stdin
unset PAT
sbx kit inspect docker.io/docker/sbx-kit-shell:1.0.0
```

sbx keeps the session inside the sandbox, so use a dedicated read-only PAT.

Without a sign-in, some commands still work with `--offline`, for example on local v1/v2 kit directories:

```console
sbx kit validate ./my-v2-kit/ --offline
sbx kit inspect ./my-v2-kit/ --offline --format json | jq
```

## What it adds

Everything the tarball's `install.sh` installs, under `/usr/local`:

- `bin/sbx` — the CLI (statically linked)
- `libexec/mkfs.ext4`, `libexec/mkfs.erofs` — filesystem image tools
- `libexec/containerd-shim-nerdbox-v1` — the runtime shim that starts sandbox microVMs
- `libexec/nerdbox-kernel-*`, `libexec/nerdbox-rootfs-*.erofs`, `libexec/sailor-rootfs-*.erofs` — kernel and root filesystems for those VMs
- `libexec/docker-docklet`, `libexec/lib/libsailor.so` — further sbx runtime components

## How it works

### Install and pin

The recipe downloads the release tarball for the target architecture, runs its own `install.sh` with `PREFIX=/out/usr/local`, and ships the result on `FROM scratch`. The build fails unless `sbx version` reports the pinned release, so `provides: ["sbx@<version>"]` is a claim the content backs.

`get.docker.com` with `SBX=1` is not used: it installs the `docker-sbx` apt package together with the whole Docker Engine, and an apt install cannot travel in an overlay. A nixpkgs build of `docker-sbx` would run on musl too, but Nix can only build it for the build machine's own architecture (the package is unfree and not in the binary cache), so it cannot be published for amd64 and arm64 from one runner.

### Network policy

All hosts are runtime-only; the install happens at build time, so the sandbox needs no install-phase access.

- `login.docker.com`, `hub.docker.com`, `api.docker.com` — sign-in and the Hub API
- `registry-1.docker.io`, `auth.docker.io`, `production.cloudfront.docker.com` — pulling kits by reference

`api.sandboxes-cloud.docker.com` is left out, so `sbx --cloud` does not work: it needs the device-flow sign-in that does not work yet, and is untested.

### The credential and `dockerSentinel`

The descriptor declares an optional `credential@1` for the proxy-managed route: `sbx login` runs the device flow inside the sandbox while the real tokens stay on the host. sbx parses its access token as a JWT and reads the username from it, so the placeholder has to be JWT-shaped. The optional `dockerSentinel` arg carries it into the credential config at sandbox create. The `SENTINEL` line below builds one that carries no secret (fixed header, your Docker ID, dummy ids, a far-future expiry, signature segment `proxy-managed`), and the arg's `pattern` admits only such placeholders, so a real token cannot be passed this way:

```console
DOCKER_ID=<docker-id>
SENTINEL="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.$(printf '{"iss":"https://api.docker.com/","aud":"https://hub.docker.com","sub":"proxy-managed","exp":4102444800,"iat":1767225600,"jti":"proxy-managed","scope":"","source":{"id":"proxy-managed","type":"pat"},"https://hub.docker.com":{"username":"%s","uuid":"00000000-0000-0000-0000-000000000000","email":"proxy-managed@example.invalid","roles":[],"session_id":"proxy-managed","source":"pat"}}' "$DOCKER_ID" | base64 | tr '+/' '-_' | tr -d '=\n').cHJveHktbWFuYWdlZA"
sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
  --kit "git+https://github.com/alakae/sbx-kits.git#dir=sbx" \
  --kit-arg sbx.dockerSentinel="$SENTINEL" \
  .
```

This route **does not work with sbx v0.51.0**: the proxy intercepts the token endpoint and rejects the device-code grant (`proxy: OAuth request denied (unrecognized grant)`). The entry and the arg are kept so it works unchanged once sbx accepts `urn:ietf:params:oauth:grant-type:device_code`. Until then, use the PAT route above.

## Limitations

- **musl:** `sbx` itself runs on Alpine, but `mkfs.*` and the shim link against glibc and do not start there, so daemon-backed commands need a glibc base.
- **Local v3 kits:** commands that load a local v3 kit build it with the workload's Docker and buildx, so they need both.
- **`/dev/kvm`:** the microVM parts (shims, kernel, rootfs images), and the commands that manage sandboxes through them, need `/dev/kvm`. sbx does not expose it inside its own sandboxes; a different v3 runtime might.

# cloudscale-api

A mixin that allows sandbox access to `api.cloudscale.ch` and injects your
cloudscale API token automatically via the proxy — the agent never sees the
real token.

## Usage

```console
$ sbx run shell \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=cloudscale-api" \
    ~/my-project
```

## What it adds

- Outbound HTTPS to `api.cloudscale.ch:443` allowed through the network policy
- `Authorization: Bearer <token>` header injected on every request to `api.cloudscale.ch`
- `CLOUDSCALE_API_TOKEN` set to `proxy-managed` inside the sandbox (the real value never leaves the host)

## Token setup

Store the token as a sandbox secret on your host (one-time, global):

```console
$ echo "$CLOUDSCALE_API_TOKEN" | sbx secret set -g cloudscale
```

## Verify

```console
$ sbx kit validate ./cloudscale-api
$ sbx kit inspect  ./cloudscale-api
```

Inside the sandbox, any HTTP call to `api.cloudscale.ch` gets the token injected
automatically — no manual `Authorization` header needed:

```console
$ curl https://api.cloudscale.ch/v1/servers
```

# cloudscale-api

A mixin that allows sandbox access to `api.cloudscale.ch` and injects your
cloudscale API token automatically via the proxy — the agent never sees the
real token.

## Usage

The kit only declares *what* it needs — a `cloudscale` credential injected as
an `Authorization: Bearer` header on requests to `api.cloudscale.ch`. Store
the token on your host once, under that service name:

```console
$ sbx secret set cloudscale
Enter secret: <<your-token-here>>
```

Then approve this kit's use of it. `sbx` asks the first time you run the kit
interactively; for `--detach`, scripts or CI, write the binding yourself in
`~/.config/sbx/credentials.yaml` (merge it into the file if one exists):

```yaml
bindings:
  cloudscale:
    apiKey:
      domains: [api.cloudscale.ch]
```

Without a binding `sbx` starts the sandbox anyway, prints `no binding
authorizes cloudscale — the credential was not injected`, and the API answers
`Authentication credentials were not provided.`

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=cloudscale-api" \
    ~/my-project
```

## What it adds

- Outbound access to `api.cloudscale.ch` (any port) allowed through the network policy
- `Authorization: Bearer <token>` header injected on every request to `api.cloudscale.ch`
- `CLOUDSCALE_API_TOKEN` set to `proxy-managed` inside the sandbox (the real value never leaves the host)


## Verify

```console
$ docker buildx build ./cloudscale-api -f ./cloudscale-api/cloudscale-api.yaml --output type=cacheonly
$ sbx kit inspect  ./cloudscale-api
```

Inside the sandbox, any HTTP call to `api.cloudscale.ch` gets the token injected
automatically — no manual `Authorization` header needed:

```console
$ curl https://api.cloudscale.ch/v1/servers
```

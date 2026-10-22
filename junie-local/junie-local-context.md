## Sandbox environment

You are running inside a Docker sandbox. This kit allows exactly one host,
the local inference engine at http://host.docker.internal:19239, and no
cloud LLM provider, package registry or git forge. Other kits added to the
sandbox may allow more, so do not assume a request will fail: try it, and if
the sandbox blocks it, tell the user which host was refused instead of
working around it. The workspace is mounted at its absolute host path.

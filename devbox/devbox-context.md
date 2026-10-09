## Devbox

Devbox is installed in this sandbox. It manages reproducible package
environments via Nix (single-user, no daemon).

- To add a package: `devbox add <package>` then `devbox install`
- To run a command in the Devbox environment: `devbox run -- <command> [args]`
  (the `--` separator is required so arguments are not misread as devbox flags)
- Always prefer `devbox run -- <cmd>` over bare `<cmd>` for packages
  managed by Devbox — PATH is not modified globally
- Do not use `devbox shell` — it opens an interactive subshell and
  will hang in a non-interactive context

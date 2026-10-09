## Nix

Nix is installed in single-user mode. Use it to run tools without installing
them permanently.

- Run a command with a package: `nix-shell -p <package> --run <command>`
- Do not use `nix-shell` without `--run` — it opens an interactive subshell
  and will hang in a non-interactive context
- No daemon — single-user profile under /home/agent/.nix-profile

`test-kit.sh`, `discover-kits.sh` and `.github/workflows/tck.yml` are based on [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib/tree/b47f8d559e1703d1bd8a8ecd53ec306623f53e13) at that commit on its `v3` branch (Apache-2.0). The license text is in `LICENSE-APACHE` beside this file.

Modified for alakae/sbx-kits:

- test-kit.sh: verbatim, plus an `--inspect` flag (marked in the file) that runs `sbx kit inspect` on the kit after kit-tck passes, for local runs.
- discover-kits.sh: same logic, without the call to contrib's `check-kit-name.sh`, which guards a Docker Hub namespace this repository does not publish to; comments rewritten for this repository.
- tck.yml: only the `test-kit` job, with its kit-tck release install, conformance step and fork-PR `--validate-only` leg. Kits are listed directly instead of through `detect-changes` path filtering. Dropped: the `conformance` gate job, `test-tck`, `test-scripts` and the e2e jobs. Added: a weekly schedule; the fork-PR guards are written as "not a pull request, or not from a fork" so the scheduled run also gets full conformance. Action pins resolved independently (with pinact) rather than copied.

`lint-kit.sh` and `.github/workflows/lint.yml` are this repository's own.

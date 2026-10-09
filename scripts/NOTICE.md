`discover-kits.sh` is based on [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib/tree/7f8518ce98d439a35096ff7f6d00e9b8f65b0f53/scripts/discover-kits.sh) (Apache-2.0).

The kit workflow `.github/workflows/kit-tests.yml` is adapted from the same commit's [`.github/workflows/tck.yml`](https://github.com/docker/sbx-kits-contrib/tree/7f8518ce98d439a35096ff7f6d00e9b8f65b0f53/.github/workflows/tck.yml), and the build step in `test-kit.sh` follows its [`scripts/test-kit.sh`](https://github.com/docker/sbx-kits-contrib/tree/7f8518ce98d439a35096ff7f6d00e9b8f65b0f53/scripts/test-kit.sh). The license text is in `LICENSE-APACHE` beside this file.

Modified for alakae/sbx-kits:

- discover-kits.sh: comments shortened and rewritten for this repository; logic unchanged.
- test-kit.sh: this repository's own script, reworked for v3 (build with the kit frontend, optional `sbx kit inspect`, shellcheck, yamllint). It takes contrib's `docker buildx build ... --output type=cacheonly` validation and its bash 3.2-safe `--platform` expansion; there is no kit-tck conformance step.
- kit-tests.yml: kit discovery and the buildx setup follow contrib; there is no change detection, kit-tck or e2e job, and sbx is installed from the stable channel.

#!/usr/bin/env bash
# Adapted from docker/sbx-kits-contrib@7f8518ce98d439a35096ff7f6d00e9b8f65b0f53
# scripts/discover-kits.sh (Apache-2.0); see scripts/NOTICE.md.
#
# Print every kit directory at the repo root, one per line, sorted.
#
# A kit is any directory holding a v3 descriptor named after itself,
# `<dir>/<dir>.yaml`. No registration list, so adding a kit needs no change
# here or in the CI workflow that calls this script.
#
# The name has to match the directory because the kit frontend pairs
# `<dir>.yaml` with its recipe `<dir>.dockerfile` by filename stem. The same
# rule keeps non-kit directories (scripts/, .github/) out without an ignore
# list.
set -euo pipefail

# Anchor to the repo root so this works from any working directory.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR/.."

# `*/` so only directories are considered; sort -u de-dupes a kit carrying
# both `.yaml` and `.yml`.
for dir in */; do
  kit=${dir%/}
  if [ -f "$kit/$kit.yaml" ] || [ -f "$kit/$kit.yml" ]; then
    printf '%s\n' "$kit"
  fi
done | sort -u

#!/usr/bin/env bash
# From docker/sbx-kits-contrib@b47f8d5 scripts/discover-kits.sh (Apache-2.0),
# without its reserved-name check; see scripts/NOTICE.md.
#
# Print every kit directory at the repo root, one per line, sorted.
#
# A kit is any directory holding a descriptor named after itself —
# `<dir>/<dir>.yaml`. No registration list, so adding a kit needs no change
# here or in any of this script's callers.
#
# Why the name has to match the directory: the kit frontend pairs `<dir>.yaml`
# with its recipe `<dir>.dockerfile` by filename stem, so the stem is already
# load-bearing. The same rule keeps non-kit directories out without an ignore
# list: `scripts/` and `.github/` hold no file named after themselves, so they
# are not kits by construction rather than by exception.
#
# Contrib also refuses kits named `*-kit` or `*-image` here (check-kit-name.sh),
# because those names collide with artifacts in its Docker Hub namespace. This
# repository publishes nothing, so the check is left out.
#
# Used by both workflows (tck.yml and lint.yml), so what counts as a kit is
# defined in exactly one place.
set -euo pipefail

# Anchor to the repo root so this works regardless of the caller's cwd —
# run from a kit subdirectory otherwise, the glob below matches nothing and
# the script silently prints an empty list instead of erroring.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR/.."

# `*/` rather than `*` so only directories are considered: a stray top-level
# file would otherwise be probed as though it were a kit directory.
#
# sort -u de-dupes a kit carrying both `.yaml` and `.yml` (mid-rename, say),
# which would otherwise list it twice and spawn two matrix legs.
kits=()
for dir in */; do
  kit=${dir%/}
  if [ -f "$kit/$kit.yaml" ] || [ -f "$kit/$kit.yml" ]; then
    kits+=("$kit")
  fi
done

# The empty case is handled before printf rather than by it: `printf '%s\n'`
# with NO operands still applies the format once and writes a bare newline, so a
# repository with no kit directories would emit one empty line instead of
# nothing. A caller doing `kits=$(discover-kits.sh | jq -R . | jq -sc .)` then
# gets `[""]` rather than `[]` and spawns a matrix leg whose kit name is the
# empty string.
[ ${#kits[@]} -gt 0 ] || exit 0

printf '%s\n' "${kits[@]}" | sort -u

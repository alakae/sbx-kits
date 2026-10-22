#!/usr/bin/env bash
# Validate, build and lint a single v3 kit.
#
# Usage:
#   scripts/test-kit.sh <kit-dir>             # from repo root
#   ../scripts/test-kit.sh                    # from inside the kit's directory
#   scripts/test-kit.sh --inspect <kit-dir>   # also run `sbx kit inspect`
#
# Runs the same checks locally and in CI (.github/workflows/kit-tests.yml):
#   1. docker buildx build   — the `# syntax=docker/sandbox-kit:3` frontend
#                              validates the descriptor and builds the recipe
#                              (if any) in one pass, exported as an OCI layout
#                              into a temporary directory
#   2. kit-tck validate      — judges that layout against the spec's
#                              conformance checks (descriptor rules the
#                              frontend does not enforce, overlay ownership,
#                              dangling links); skipped with a warning when
#                              kit-tck is not installed, required in CI
#   3. sbx kit inspect       — only with --inspect: resolves the kit the way
#                              sbx will (needs a running sbx, v0.45.0 or newer)
#   4. shellcheck            — any *.sh shipped by the kit
#   5. yamllint              — the descriptor and any other YAML in the kit
#
# `sbx kit validate` is deliberately not used: it cannot load a v3 source kit
# ("no kit builder configured"), so it fails on every kit in this repo.
#
# Requires `docker` with buildx, `shellcheck` and `yamllint` on PATH, and `sbx`
# for --inspect (see README for install instructions). `kit-tck` is optional
# locally; build it from a clone of github.com/docker/sandbox-kit-spec with
# `go build -buildvcs=false -o ~/.local/bin/kit-tck ./cmd/kit-tck` (CI pins the commit it
# uses in .github/workflows/kit-tests.yml).
#
# Environment:
#   PLATFORM         value for `docker buildx build --platform` (default: native)
#   REQUIRE_KIT_TCK  set to 1 to fail instead of skipping when kit-tck is
#                    missing (CI sets it)

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

inspect=
if [ "${1:-}" = "--inspect" ]; then
  inspect=1
  shift
fi

kit_arg=${1:-$PWD}

if [ -d "$kit_arg" ]; then
  kit_abs=$(cd "$kit_arg" && pwd)
elif [ -d "$REPO_ROOT/$kit_arg" ]; then
  kit_abs=$(cd "$REPO_ROOT/$kit_arg" && pwd)
else
  echo "kit directory not found: $kit_arg" >&2
  exit 1
fi

# The same contract scripts/discover-kits.sh uses to decide what a kit is.
kit_name=$(basename "$kit_abs")
descriptor="$kit_abs/$kit_name.yaml"
if [ ! -f "$descriptor" ]; then
  echo "no $kit_name.yaml in $kit_abs — is this a v3 kit directory?" >&2
  exit 1
fi

layout=$(mktemp -d "${TMPDIR:-/tmp}/kit-layout.XXXXXX")
trap 'rm -rf "$layout"' EXIT

echo "== $kit_name: docker buildx build (validate + build) =="
# The kit directory is the build context and the descriptor is the
# "Dockerfile". PLATFORM is expanded with ${VAR:+...} so an unset value adds
# nothing (macOS bash 3.2 cannot expand an empty array under `set -u`).
# The OCI layout export is what kit-tck judges below; the tag only names the
# image inside it.
docker buildx build "$kit_abs" \
  -f "$descriptor" \
  ${PLATFORM:+--platform "$PLATFORM"} \
  -t "$kit_name:test" \
  --output "type=oci,dest=$layout/oci,tar=false"

echo "== $kit_name: kit-tck validate =="
if command -v kit-tck >/dev/null 2>&1; then
  # The tag alone, as the layout records it — not "$kit_name:test".
  kit-tck validate --layout "$layout/oci" test
elif [ "${REQUIRE_KIT_TCK:-}" = 1 ]; then
  echo "kit-tck not found on PATH, and REQUIRE_KIT_TCK=1" >&2
  exit 1
else
  echo "kit-tck not installed — skipping (see the header of this script)" >&2
fi

if [ -n "$inspect" ]; then
  echo "== $kit_name: sbx kit inspect =="
  sbx kit inspect "$kit_abs" </dev/null
fi

echo "== $kit_name: shellcheck =="
shell_scripts=$(find "$kit_abs" -type f -name '*.sh')
if [ -n "$shell_scripts" ]; then
  # shellcheck disable=SC2086
  shellcheck $shell_scripts
else
  echo "no shell scripts in $kit_name — skipping"
fi

echo "== $kit_name: yamllint =="
yaml_files=$(find "$kit_abs" -type f \( -name '*.yaml' -o -name '*.yml' \))
# shellcheck disable=SC2086
yamllint -c "$REPO_ROOT/.yamllint.yml" $yaml_files

echo "== $kit_name: OK =="

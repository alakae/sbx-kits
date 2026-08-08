#!/usr/bin/env bash
# Validate and lint a single kit.
#
# Usage:
#   scripts/test-kit.sh <kit-dir>   # from repo root
#   ../scripts/test-kit.sh          # from inside the kit's directory
#   ../scripts/test-kit.sh my-kit   # also works
#
# Runs the same checks locally and in CI (.github/workflows/kit-tests.yml):
#   1. sbx kit validate  — spec.yaml is well-formed
#   2. sbx kit inspect    — spec.yaml resolves to a valid manifest
#   3. shellcheck         — any *.sh shipped by the kit
#   4. yamllint            — spec.yaml and any *.yaml/*.yml under files/
#
# Requires `sbx`, `shellcheck`, and `yamllint` on PATH (see README for
# install instructions).

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

kit_arg=${1:-$PWD}

if [ -d "$kit_arg" ]; then
  kit_abs=$(cd "$kit_arg" && pwd)
elif [ -d "$REPO_ROOT/$kit_arg" ]; then
  kit_abs=$(cd "$REPO_ROOT/$kit_arg" && pwd)
else
  echo "kit directory not found: $kit_arg" >&2
  exit 1
fi

if [ ! -f "$kit_abs/spec.yaml" ] && [ ! -f "$kit_abs/spec.yml" ]; then
  echo "no spec.yaml/spec.yml in $kit_abs — is this a kit directory?" >&2
  exit 1
fi

kit_name=$(basename "$kit_abs")

echo "== $kit_name: sbx kit validate =="
sbx kit validate "$kit_abs"

echo "== $kit_name: sbx kit inspect =="
sbx kit inspect "$kit_abs" --json | jq . >/dev/null

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

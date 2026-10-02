#!/usr/bin/env bash
# Lint one kit: shellcheck its shell scripts, yamllint its YAML.
#
# Usage:
#   scripts/lint-kit.sh <kit-dir>    # from repo root
#   ../scripts/lint-kit.sh           # from inside the kit's directory
#
# Separate from scripts/test-kit.sh, which builds the kit and runs kit-tck on
# the result: linting needs neither docker nor kit-tck. CI runs it from
# .github/workflows/lint.yml for every kit scripts/discover-kits.sh lists.
#
# Requires `shellcheck` and `yamllint` on PATH (`uv tool install yamllint`).

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

kit_arg=${1:-$PWD}

# The same resolution as scripts/test-kit.sh: absolute, relative to $PWD, or
# relative to the repo root.
if [ -d "$kit_arg" ]; then
  kit_abs=$(cd "$kit_arg" && pwd)
elif [ -d "$REPO_ROOT/$kit_arg" ]; then
  kit_abs=$(cd "$REPO_ROOT/$kit_arg" && pwd)
else
  echo "kit directory not found: $kit_arg" >&2
  exit 1
fi

kit_name=$(basename "$kit_abs")
if [ ! -f "$kit_abs/$kit_name.yaml" ]; then
  echo "no $kit_name.yaml in $kit_abs — is this a v3 kit directory?" >&2
  exit 1
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

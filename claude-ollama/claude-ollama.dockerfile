# syntax=docker/dockerfile:1

# Content recipe for the `claude-ollama` workload kit.
#
# A workload's layers are its root filesystem, so it must have content. The
# template supplies the platform floor plus the `claude` binary the wrapper
# execs.
FROM docker/sandbox-templates:claude-code-docker

# Re-pin Claude Code to the release this kit publishes.
#
# The template above already ships a `claude`, but a floating one — it is a
# nightly-rebuilt tag. The descriptor publishes
# `claude-ollama@${{ kit.args.version }}`, and the wrapper below is
# `exec claude "$@"`, so that provide is a statement about the binary the
# template supplies. Letting it float underneath a version the descriptor
# asserts would be worse than publishing no version at all, which is why this
# layer exists.
#
# Anthropic's own installer does the work: the value is its one positional
# target, which is the same target the installed binary's
# `claude install [target]` takes. It runs as the base's inherited non-root `agent` user, so it replaces
# the binary in /home/agent/.local/bin that the template already put on PATH,
# in the tree that `claude update` later writes to.
#
# No default on the ARG: the descriptor always supplies one, and an empty value
# would silently fall back to the installer's own channel while the provide
# went on claiming the pinned number.
#
# The installed binary is asked for its version and the answer compared against
# the pin — the installer's exit code says only that the script ran, and a
# `curl | bash` whose curl dies after partial output still exits 0.
# `claude --version` prints "<version> (Claude Code)", so the first field is
# the number to match.
ARG CLAUDE_CODE_VERSION
RUN <<EOF
set -eux
[ -n "${CLAUDE_CODE_VERSION}" ] || { echo "CLAUDE_CODE_VERSION must be set" >&2; exit 1; }
curl -fsSL https://claude.ai/install.sh | bash -s -- ${CLAUDE_CODE_VERSION}
installed=$(claude --version | awk '{print $1}')
[ "$installed" = "${CLAUDE_CODE_VERSION}" ] || {
  echo "installed claude $installed != pinned ${CLAUDE_CODE_VERSION}" >&2; exit 1; }
EOF

# Static env, in the slot OCI already owns for it. The wrapper script the kit
# writes reads this at run time and fans it out across every Claude Code model
# alias, so one value switches the whole session. Override it per sandbox, or pin a different default in a fork.
ENV CLAUDE_OLLAMA_MODEL=gemma4:e4b-it-q4_K_M

# The image config carries the runtime contract and the descriptor duplicates
# none of it. The target is the wrapper the kit's lifecycle `files:` entry
# writes, which the runtime lands before the entrypoint first runs.
ENTRYPOINT ["/home/agent/.local/bin/claude-ollama"]

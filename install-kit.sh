#!/usr/bin/env bash
# Installs (or reinstalls) the kit's skills and agents in ~/.claude/.
# Same as install-kit.ps1: each skill is replaced whole (no stale files left), agents are
# overwritten, and nothing that is not the kit's is touched.
#
#   bash install-kit.sh          # from the kit's folder, or with its path
#   bash install-kit.sh --pull   # git pull first
#
# At the end it writes ~/.claude/web-agent-kit.json (clone path and installed version) for
# the kit-update skill.
#
# Afterwards: a new Claude Code session (skills and agents load at startup).
set -euo pipefail

kit="$(cd "$(dirname "$0")" && pwd)"
target="$HOME/.claude"

if [[ "${1:-}" == "--pull" ]]; then
  echo "... git pull in $kit"
  git -C "$kit" pull --ff-only
fi

version="$(tr -d '[:space:]' < "$kit/VERSION")"
echo "Kit $version -> $target"
mkdir -p "$target/skills" "$target/agents"

for skill in "$kit"/.claude/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "${target:?}/skills/$name"
  cp -r "$skill" "$target/skills/$name"
  echo "  + skill  $name"
done

for agent in "$kit"/.claude/agents/*.md; do
  cp "$agent" "$target/agents/"
  echo "  + agent  $(basename "$agent" .md)"
done

# For kit-update: where the clone is and which skills version got installed.
printf '{\n  "path": "%s",\n  "version": "%s",\n  "installed": "%s"\n}\n' \
  "$kit" "$version" "$(date +%F)" > "$target/web-agent-kit.json"
echo "  + web-agent-kit.json (path and version, for kit-update)"

echo
echo "Done. Open a new Claude Code session and check with /skills and /agents."

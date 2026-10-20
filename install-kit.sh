#!/usr/bin/env bash
# Installs (or reinstalls) the kit's skills and agents in ~/.claude/.
# Same as install-kit.ps1: each skill is replaced whole (no stale files left), agents are
# overwritten, and nothing that is not the kit's is touched.
#
#   bash install-kit.sh          # from the kit's folder, or with its path
#   bash install-kit.sh --pull   # git pull first
#   bash install-kit.sh --project <path>   # into <path>/.claude/ instead (cloud sessions)
#
# At the end it writes ~/.claude/web-agent-kit.json (clone path and installed version) for
# the kit-update skill.
#
# --project copies them into a project's .claude/ (committed with it): a Claude Code cloud
# session only loads what is in the repo, never ~/.claude/. No web-agent-kit.json there: the
# project's .kit-version says which version its copy is.
#
# Afterwards: a new Claude Code session (skills and agents load at startup).
set -euo pipefail

kit="$(cd "$(dirname "$0")" && pwd)"
target="$HOME/.claude"
project=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull) echo "... git pull in $kit"; git -C "$kit" pull --ff-only ;;
    --project) project="${2:?--project needs a path}"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
if [[ -n "$project" ]]; then
  [[ -f "$project/package.json" ]] || { echo "There is no package.json in $project" >&2; exit 1; }
  target="$(cd "$project" && pwd)/.claude"
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

if [[ -n "$project" ]]; then
  echo
  echo "Done. Commit $target/skills and $target/agents with the project."
  exit 0
fi

# For kit-update: where the clone is and which skills version got installed.
printf '{\n  "path": "%s",\n  "version": "%s",\n  "installed": "%s"\n}\n' \
  "$kit" "$version" "$(date +%F)" > "$target/web-agent-kit.json"
echo "  + web-agent-kit.json (path and version, for kit-update)"

echo
echo "Done. Open a new Claude Code session and check with /skills and /agents."

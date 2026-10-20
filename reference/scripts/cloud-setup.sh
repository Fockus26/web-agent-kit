#!/usr/bin/env bash
# SessionStart hook (.claude/settings.json): prepares a Claude Code CLOUD session.
# On César's machine it does nothing (CLAUDE_CODE_REMOTE is only "true" in the cloud).
#
# Why: a cloud session starts in a fresh container with only the repo cloned. Without
# node_modules nothing builds, and without the gitignored files of context/ (CURRENT_PHASE,
# plans/, CONTENT_CHECKLIST…) the agent starts blind about the phase and the wave. This
# brings both back before the first prompt. It never fails the session: whatever it cannot
# do, it prints, and the cloud-session skill picks it up.
set -uo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if command -v bun >/dev/null 2>&1; then
  if [ ! -d node_modules ]; then
    if bun install --frozen-lockfile >/dev/null 2>&1 || bun install >/dev/null 2>&1; then
      echo "cloud-setup: bun install ok"
    else
      echo "cloud-setup: bun install FAILED - run it by hand"
    fi
  fi
else
  echo "cloud-setup: bun is not installed in this environment - add it to the environment's setup script"
fi

if [ ! -e context/CURRENT_PHASE.md ] && [ -f scripts/context-backup.sh ]; then
  bash scripts/context-backup.sh --restore 2>&1 | tail -1 | sed 's/^/cloud-setup: /'
fi
exit 0

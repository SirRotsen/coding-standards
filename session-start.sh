#!/bin/bash
#
# SessionStart hook: print the shared coding standards, then this repo's publish
# state. Every failure exits 0—a session without standards is degraded, not
# broken, and a hook must never be the thing that stops work.
set -uo pipefail

BASE="${CODING_STANDARDS_BASE:-https://raw.githubusercontent.com/SirRotsen/coding-standards/main}"

fetch() {
  curl -fsSL --connect-timeout 3 --max-time 10 "$BASE/$1" 2>/dev/null
}

emit() {
  body=$(fetch "$1") || return 0
  [ -n "$body" ] || return 0
  printf '\n===== %s (shared standards, fetched at session start) =====\n\n' "$1"
  printf '%s\n' "$body"
  printf '\n===== end %s =====\n' "$1"
}

emit CODING-STANDARDS.md
emit REVIEW.md

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Decide before fetching: a repo that doesn't publish by merge says nothing,
# and shouldn't pay for a network round trip whose result it discards.
git rev-parse --verify --quiet origin/main >/dev/null || exit 0
git rev-parse --verify --quiet origin/deploy >/dev/null || exit 0

git fetch --quiet origin main deploy 2>/dev/null || true

printf '\n'
ahead=$(git rev-list --count origin/deploy..origin/main 2>/dev/null || echo 0)
if [ "$ahead" -gt 0 ]; then
  echo "Publish state: main is $ahead commit(s) ahead of deploy—merged work has NOT shipped. Publishing is merging main into deploy, unless this repo's CLAUDE.md says otherwise."
  git --no-pager log --oneline origin/deploy..origin/main | head -5 | sed 's/^/  /'
else
  echo "Publish state: main and deploy match—everything merged is live."
fi
exit 0

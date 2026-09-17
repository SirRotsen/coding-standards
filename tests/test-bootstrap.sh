#!/bin/bash
#
# What bin/hq must keep doing. It executes at session start in every repo and
# runs code fetched over the network, so its refusals matter more than its
# happy path: the traversal cases below are a fix for a real hole, not a
# hypothetical.
#
# Usage: tests/test-bootstrap.sh [ref]   (default: main)
set -uo pipefail

REF="${1:-main}"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
mkdir -p "$REPO/.claude/bin"
cp "$HERE/bin/hq" "$REPO/.claude/bin/hq"
chmod +x "$REPO/.claude/bin/hq"
HQ="$REPO/.claude/bin/hq"
CACHE="$REPO/.claude/.cache"

pass=0
fail=0

ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$1"; }
check(){ if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected $3, got $2)"; fi; }

run() { CLAUDE_PROJECT_DIR="$REPO" HQ_BOOTSTRAP_REF="$2" "$HQ" "$1" "${@:3}" >"$WORK/out" 2>"$WORK/err"; echo $?; }

echo "Refusals:"

for evil in "../../anthropics/anthropic-sdk-python/main" "main/../../../etc" "/main" "main;id" 'main$(id)' "main ref" "main/"; do
  code=$(run session-start "$evil")
  if [ "$code" = 2 ] && grep -q "refusing the ref" "$WORK/err"; then
    ok "refuses ref '$evil'"
  else
    bad "ref '$evil' was not refused (exit $code)"
  fi
done

# An empty ref is an unset one: it falls back to main rather than building a
# URL with a hole in it.
code=$(run session-start "")
if [ "$code" != 2 ]; then ok "an empty ref falls back to main"; else bad "an empty ref was refused instead of defaulting"; fi

check "unknown subcommand exits 2" "$(run bogus "$REF")" 2
code=$(CLAUDE_PROJECT_DIR="$REPO" "$HQ" >/dev/null 2>&1; echo $?)
check "no subcommand exits 2" "$code" 2

echo "Cold cache, unreachable payload:"

rm -rf "$CACHE"
code=$(run session-start "no-such-ref-$$")
check "session-start stays silent and exits 0" "$code" 0
check "  and prints nothing" "$(wc -c <"$WORK/out" | tr -d ' ')" 0

code=$(run drop "no-such-ref-$$" projects)
check "drop exits 1" "$code" 1
if grep -q "could not fetch" "$WORK/err"; then ok "  and says why"; else bad "drop failed silently"; fi

echo "Junk never runs:"

mkdir -p "$CACHE"
printf '<html><body>404: Not Found</body></html>' >"$CACHE/no-such-ref-$$.drop"
chmod +x "$CACHE/no-such-ref-$$.drop"
code=$(run drop "no-such-ref-$$" projects)
check "an HTML error page in the cache is refused" "$code" 1

printf '#!/bin/sh\necho ran\n' >"$CACHE/no-such-ref-$$.drop"
chmod +x "$CACHE/no-such-ref-$$.drop"
code=$(run drop "no-such-ref-$$" projects)
check "a too-short script in the cache is refused" "$code" 1

echo "Fetching (needs network):"

if ! curl -fsSL --max-time 10 -o /dev/null "https://raw.githubusercontent.com/SirRotsen/coding-standards/$REF/payload/session-start"; then
  echo "  SKIP: cannot reach the payload for ref '$REF'"
else
  rm -rf "$CACHE"
  code=$(run session-start "$REF")
  check "session-start runs and exits 0" "$code" 0
  if grep -q "CODING-STANDARDS.md" "$WORK/out"; then ok "  prints the standards"; else bad "no standards in the output"; fi
  if grep -q "REVIEW.md" "$WORK/out"; then ok "  prints the review rubric"; else bad "no rubric in the output"; fi
  if [ -s "$CACHE/$REF.session-start" ]; then ok "  caches the payload under its ref"; else bad "nothing cached for ref $REF"; fi
  if [ ! -e "$CACHE/$REF.session-start.new" ]; then ok "  leaves no partial file behind"; else bad "a .new file survived"; fi

  # The documents must come from the same ref as the payload, or testing a
  # branch silently reads main.
  if [ "$REF" != main ]; then
    if HQ_STANDARDS_BASE="https://raw.githubusercontent.com/SirRotsen/coding-standards/$REF" \
       HQ_REPO_ROOT="$REPO" "$CACHE/$REF.session-start" >/dev/null 2>&1; then
      ok "  payload honors the ref it was fetched from"
    else
      bad "payload failed when pointed at ref '$REF'"
    fi
  fi

  printf '<html>not a script</html>' >"$CACHE/$REF.drop"
  run drop "$REF" projects >/dev/null 2>&1 || true
  if head -1 "$CACHE/$REF.drop" | grep -q '^#!'; then ok "  a good fetch replaces junk in the cache"; else bad "junk survived a good fetch"; fi

  # A read-only .claude costs the cache, never the run.
  rm -rf "$CACHE"
  chmod 555 "$REPO/.claude"
  code=$(run session-start "$REF")
  chmod 755 "$REPO/.claude"
  check "an unwritable cache still runs the fetched payload" "$code" 0
  if grep -q "CODING-STANDARDS.md" "$WORK/out"; then ok "  and still prints the standards"; else bad "output lost when the cache was unwritable"; fi
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

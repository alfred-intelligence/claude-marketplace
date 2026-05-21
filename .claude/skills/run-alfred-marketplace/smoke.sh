#!/usr/bin/env bash
# smoke.sh — end-to-end check of the alfred Claude Code marketplace.
#
#   validate manifest  →  add at local scope  →  list  →  cleanup
#
# Run from anywhere inside the repo. Cleanup runs on any exit (trap),
# so a half-finished run won't leave the marketplace registered.
#
# Exit codes: 0 = all checks passed, 1 = at least one failed,
#             2 = not in a git repo / wrong place.

set -u

# Anchor to the repo this script lives in, so it works regardless of cwd.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null) || {
  echo "✘ can't find repo root — is this script still inside the marketplace repo?" >&2
  exit 2
}
cd "$REPO_ROOT"

ROOT=$PWD
MANIFEST="$ROOT/.claude-plugin/marketplace.json"
NAME=$(jq -r .name "$MANIFEST")

cleanup() {
  claude plugin marketplace remove "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

pass=0; fail=0
ok() { echo "  ✔ $1"; pass=$((pass+1)); }
no() { echo "  ✘ $1"; fail=$((fail+1)); }

echo "── 1. Validate manifest ──"
out=$(claude plugin validate "$MANIFEST" 2>&1)
echo "$out" | sed 's/^/    /'
echo "$out" | grep -q "Validation passed" && ok "manifest valid" || no "validation failed"

echo
echo "── 2. Add at local scope ──"
# Drop any leftover from a prior aborted run, then add fresh.
claude plugin marketplace remove "$NAME" >/dev/null 2>&1 || true
add_out=$(claude plugin marketplace add ./ --scope local 2>&1)
echo "$add_out" | sed 's/^/    /'
echo "$add_out" | grep -q "Successfully added marketplace: $NAME" && ok "added as $NAME" || no "add failed"

echo
echo "── 3. List shows it ──"
list_json=$(claude plugin marketplace list --json 2>&1)
if echo "$list_json" | jq -e --arg n "$NAME" '.[] | select(.name == $n)' >/dev/null; then
  echo "$list_json" | jq --arg n "$NAME" '.[] | select(.name == $n)' | sed 's/^/    /'
  ok "listed"
else
  no "not in marketplace list"
fi

echo
echo "── 4. Plugins declared ──"
mapfile -t plugins < <(jq -r '.plugins[].name' "$MANIFEST")
for p in "${plugins[@]}"; do echo "    - $p"; done
ok "${#plugins[@]} plugin(s) in manifest"

echo
echo "── Result ──"
echo "  pass=$pass  fail=$fail"
[ "$fail" -eq 0 ]

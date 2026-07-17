#!/usr/bin/env bash
# doctor.sh — machine preflight for new projects. Read-only unless --fix.
# Usage: ./doctor.sh [--fix]
set -u

FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

ok=0; bad=0
pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; ok=$((ok+1)); }
fail() { printf '  \033[31m✗\033[0m %s\n    → %s\n' "$1" "$2"; bad=$((bad+1)); }

echo "toolchain"

if xcode-select -p >/dev/null 2>&1; then
  pass "xcode command line tools"
else
  fail "xcode command line tools" "run: xcode-select --install"
fi

if command -v git >/dev/null 2>&1; then
  pass "git ($(git --version | awk '{print $3}'))"
else
  fail "git" "comes with xcode CLT above"
fi

if command -v node >/dev/null 2>&1; then
  major=$(node -v | sed 's/^v//' | cut -d. -f1)
  if [ "$major" -ge 20 ]; then
    pass "node ($(node -v))"
  else
    fail "node $(node -v) too old" "install LTS: https://nodejs.org/en/download (or tarball from https://nodejs.org/dist/latest-v22.x/ into ~/.local)"
  fi
else
  fail "node" "install LTS: https://nodejs.org/en/download (skip nvm/brew on a fresh machine)"
fi

if command -v gh >/dev/null 2>&1; then
  pass "gh ($(gh --version | head -1 | awk '{print $3}'))"
else
  fail "gh" "install: https://cli.github.com (or tarball from https://github.com/cli/cli/releases/latest into ~/.local/bin)"
fi

echo "identity"

GH_USER=""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_USER=$(gh api user --jq .login 2>/dev/null || true)
  pass "gh authenticated as ${GH_USER:-unknown}"
else
  fail "gh auth" "run: gh auth login  (GitHub.com → HTTPS → browser)"
fi

name=$(git config --global user.name 2>/dev/null || true)
email=$(git config --global user.email 2>/dev/null || true)

if [ -n "$name" ] && [ -n "$email" ]; then
  pass "git identity ($name <$email>)"
elif [ -n "$GH_USER" ] && [ "$FIX" -eq 1 ]; then
  gh_id=$(gh api user --jq .id)
  git config --global user.name "$GH_USER"
  git config --global user.email "${gh_id}+${GH_USER}@users.noreply.github.com"
  pass "git identity set from gh session ($GH_USER, noreply email)"
else
  fail "git identity" "rerun with --fix (derives noreply email from gh), or set user.name/user.email manually"
fi

echo "optional"
if command -v cursor >/dev/null 2>&1; then
  pass "cursor CLI"
else
  printf '  \033[33m-\033[0m cursor CLI not on PATH (install from Cursor: Cmd+Shift+P → "Install '\''cursor'\'' command")\n'
fi

echo
if [ "$bad" -eq 0 ]; then
  echo "ready: $ok checks passed"
  exit 0
else
  echo "not ready: $bad problem(s) above"
  exit 1
fi

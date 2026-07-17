#!/usr/bin/env bash
# install.sh — deterministic toolchain install for a fresh Mac. Idempotent.
# No sudo, no Homebrew. Writes only to ~/.local and ~/.zshrc.
# Exit 0 = done. Exit 1 = human action needed (message explains); re-run after.
set -euo pipefail

LOCAL="$HOME/.local"; BIN="$LOCAL/bin"; mkdir -p "$BIN"

# 1. Xcode command line tools (git) — needs a human click if missing
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install >/dev/null 2>&1 || true
  echo "→ A dialog is opening: install the Command Line Tools, then re-run this script."
  exit 1
fi
echo "✓ xcode command line tools"

# 2. Node LTS v22 → ~/.local/node
if command -v node >/dev/null 2>&1 || [ -x "$LOCAL/node/bin/node" ]; then
  echo "✓ node already present"
else
  case "$(uname -m)" in arm64) NARCH="darwin-arm64";; *) NARCH="darwin-x64";; esac
  NAME=$(curl -fsSL https://nodejs.org/dist/latest-v22.x/ | grep -o "node-v[0-9.]*-${NARCH}\.tar\.gz" | head -1)
  [ -n "$NAME" ] || { echo "✗ could not resolve node tarball name"; exit 1; }
  echo "… downloading $NAME"
  curl -fsSL "https://nodejs.org/dist/latest-v22.x/${NAME}" -o /tmp/node.tgz
  rm -rf "$LOCAL/node"; mkdir -p "$LOCAL/node"
  tar -xzf /tmp/node.tgz -C "$LOCAL/node" --strip-components=1
  ln -sf "$LOCAL/node/bin/node" "$LOCAL/node/bin/npm" "$LOCAL/node/bin/npx" "$BIN/"
  echo "✓ node $("$BIN/node" -v)"
fi

# 3. GitHub CLI → ~/.local/bin/gh (macOS assets are .zip)
if command -v gh >/dev/null 2>&1 || [ -x "$BIN/gh" ]; then
  echo "✓ gh already present"
else
  case "$(uname -m)" in arm64) GARCH="macOS_arm64";; *) GARCH="macOS_amd64";; esac
  URL=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
        | grep -o "https://[^\"]*${GARCH}\.zip" | head -1)
  [ -n "$URL" ] || { echo "✗ could not resolve gh release URL"; exit 1; }
  echo "… downloading $(basename "$URL")"
  curl -fsSL "$URL" -o /tmp/gh.zip
  rm -rf /tmp/ghx; mkdir -p /tmp/ghx
  unzip -q /tmp/gh.zip -d /tmp/ghx
  cp /tmp/ghx/*/bin/gh "$BIN/gh"; chmod +x "$BIN/gh"
  echo "✓ gh $("$BIN/gh" --version | head -1 | awk '{print $3}')"
fi

# 4. PATH (idempotent)
if ! grep -qs 'HOME/.local/bin' "$HOME/.zshrc" 2>/dev/null; then
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
  echo "✓ PATH added to ~/.zshrc"
else
  echo "✓ PATH already configured"
fi

echo
echo "Toolchain ready. Next, in THIS terminal (both are interactive — run them yourself):"
echo "  1. $BIN/gh auth login --hostname github.com --git-protocol https --web"
echo "  2. $(cd "$(dirname "$0")" && pwd)/doctor.sh --fix"

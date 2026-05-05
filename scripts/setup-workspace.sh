#!/usr/bin/env bash
# Installs gitignored secret files into this worktree from the local vault.
# Run once after creating a new worktree.
#
# Vault location (outside any worktree, never committed):
#   ~/conductor/secrets/GuachinchesFlutter/

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT="${GUACHINCHES_SECRETS_VAULT:-$HOME/conductor/secrets/GuachinchesFlutter}"

if [[ ! -d "$VAULT" ]]; then
  echo "✗ Vault not found at: $VAULT" >&2
  echo "  Create it and place GoogleService-Info.plist inside, then re-run." >&2
  exit 1
fi

install_file() {
  local src="$VAULT/$1"
  local dst="$REPO_ROOT/$2"
  if [[ ! -f "$src" ]]; then
    echo "✗ Missing in vault: $1" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "✓ $2"
}

install_file "GoogleService-Info.plist" "ios/Runner/GoogleService-Info.plist"

echo "Done."

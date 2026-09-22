#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "Git não encontrado."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq não encontrado."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$ROOT_DIR/.super-dev-kit/backups/git/$STAMP"
mkdir -p "$BACKUP_DIR"

keys=(
  "user.name"
  "user.email"
  "init.defaultBranch"
  "core.autocrlf"
  "pull.rebase"
  "push.autoSetupRemote"
)

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

jq -n   --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"   '{created_at:$created_at,values:{}}' > "$tmp"

for key in "${keys[@]}"; do
  value="$(git config --global --get "$key" 2>/dev/null || true)"

  if [[ -n "$value" ]]; then
    next="$(mktemp)"
    jq --arg key "$key" --arg value "$value" '.values[$key]=$value' "$tmp" > "$next"
    mv "$next" "$tmp"
  fi
done

mv "$tmp" "$BACKUP_DIR/git-config.json"
trap - EXIT

echo "[OK] Backup da configuração Git criado:"
echo "     $BACKUP_DIR"
echo "Somente chaves não sensíveis selecionadas foram exportadas."

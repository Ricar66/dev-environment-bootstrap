#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "Git não encontrado."
  exit 1
fi

if [[ ! -d .git ]]; then
  echo "Este diretório não é um clone Git."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Existem alterações locais não commitadas."
  echo "Por segurança, o auto-update foi cancelado."
  echo "Use 'git status' e salve/commit/stash suas alterações."
  exit 1
fi

echo "Buscando atualizações..."
git fetch origin

LOCAL="$(git rev-parse HEAD)"
UPSTREAM="$(git rev-parse '@{u}' 2>/dev/null || true)"

if [[ -z "$UPSTREAM" ]]; then
  echo "A branch atual não possui upstream configurado."
  exit 1
fi

if [[ "$LOCAL" == "$UPSTREAM" ]]; then
  echo "[OK] Super Dev Kit já está atualizado."
  exit 0
fi

git pull --ff-only
echo "[OK] Super Dev Kit atualizado."

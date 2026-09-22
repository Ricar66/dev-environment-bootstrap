#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_PATH=""
APPLY=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/restore-git.sh
  bash tools/restore-git.sh --backup .super-dev-kit/backups/git/AAAAMMDD-HHMMSS
  bash tools/restore-git.sh --apply
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup)
      BACKUP_PATH="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opção desconhecida: $1" >&2
      usage
      exit 1
      ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "Git não encontrado."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq não encontrado."; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="$ROOT_DIR/.super-dev-kit/backups/git"

if [[ -z "$BACKUP_PATH" ]]; then
  BACKUP_PATH="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n 1 || true)"
fi

if [[ -z "$BACKUP_PATH" ]]; then
  echo "Nenhum backup Git encontrado."
  exit 1
fi

if [[ "$BACKUP_PATH" != /* ]]; then
  BACKUP_PATH="$ROOT_DIR/$BACKUP_PATH"
fi

FILE="$BACKUP_PATH"
[[ -d "$BACKUP_PATH" ]] && FILE="$BACKUP_PATH/git-config.json"

[[ -f "$FILE" ]] || { echo "Backup não encontrado: $FILE"; exit 1; }

echo "Configurações que serão restauradas:"
jq -r '.values | to_entries[] | "  (.key) = (.value)"' "$FILE"

if [[ "$APPLY" -ne 1 ]]; then
  echo
  echo "[PREVIEW] Nada foi alterado."
  echo "Use --apply para restaurar."
  exit 0
fi

while IFS=$'	' read -r key value; do
  git config --global "$key" "$value"
done < <(jq -r '.values | to_entries[] | [.key,.value] | @tsv' "$FILE")

echo "[OK] Configuração Git restaurada."

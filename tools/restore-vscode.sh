#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_PATH=""
APPLY=0
SKIP_EXTENSIONS=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/restore-vscode.sh
  bash tools/restore-vscode.sh --backup .super-dev-kit/backups/vscode/AAAAMMDD-HHMMSS
  bash tools/restore-vscode.sh --apply
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
    --skip-extensions)
      SKIP_EXTENSIONS=1
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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="$ROOT_DIR/.super-dev-kit/backups/vscode"
USER_DIR="$HOME/.config/Code/User"

if [[ -z "$BACKUP_PATH" ]]; then
  BACKUP_PATH="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n 1 || true)"
fi

if [[ -z "$BACKUP_PATH" || ! -d "$BACKUP_PATH" ]]; then
  echo "Nenhum backup válido do VS Code encontrado."
  exit 1
fi

if [[ "$BACKUP_PATH" != /* ]]; then
  BACKUP_PATH="$ROOT_DIR/$BACKUP_PATH"
fi

echo "Backup selecionado:"
echo "  $BACKUP_PATH"
echo

for item in settings.json keybindings.json snippets extensions.txt; do
  [[ -e "$BACKUP_PATH/$item" ]] && echo "  - $item"
done

if [[ "$APPLY" -ne 1 ]]; then
  echo
  echo "[PREVIEW] Nada foi restaurado."
  echo "Use --apply para restaurar."
  exit 0
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
SAFETY_DIR="$ROOT_DIR/.super-dev-kit/backups/vscode-pre-restore/$STAMP"
mkdir -p "$SAFETY_DIR" "$USER_DIR"

for file in settings.json keybindings.json; do
  [[ -f "$USER_DIR/$file" ]] && cp "$USER_DIR/$file" "$SAFETY_DIR/$file"
  [[ -f "$BACKUP_PATH/$file" ]] && cp "$BACKUP_PATH/$file" "$USER_DIR/$file"
done

if [[ -d "$USER_DIR/snippets" ]]; then
  cp -R "$USER_DIR/snippets" "$SAFETY_DIR/snippets"
fi

if [[ -d "$BACKUP_PATH/snippets" ]]; then
  mkdir -p "$USER_DIR/snippets"
  cp -R "$BACKUP_PATH/snippets/." "$USER_DIR/snippets/"
fi

if [[ "$SKIP_EXTENSIONS" -ne 1 && -f "$BACKUP_PATH/extensions.txt" ]] && command -v code >/dev/null 2>&1; then
  while IFS= read -r extension; do
    [[ -n "$extension" ]] && code --install-extension "$extension" --force
  done < "$BACKUP_PATH/extensions.txt"
fi

echo "[OK] VS Code restaurado."
echo "Backup de segurança do estado anterior:"
echo "  $SAFETY_DIR"

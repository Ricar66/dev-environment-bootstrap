#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$ROOT_DIR/.super-dev-kit/backups/vscode/$STAMP"
USER_DIR="$HOME/.config/Code/User"

mkdir -p "$BACKUP_DIR"

for file in settings.json keybindings.json; do
  if [[ -f "$USER_DIR/$file" ]]; then
    cp "$USER_DIR/$file" "$BACKUP_DIR/$file"
  fi
done

if [[ -d "$USER_DIR/snippets" ]]; then
  cp -R "$USER_DIR/snippets" "$BACKUP_DIR/snippets"
fi

if command -v code >/dev/null 2>&1; then
  code --list-extensions > "$BACKUP_DIR/extensions.txt"
fi

cat > "$BACKUP_DIR/metadata.json" <<EOF
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "platform": "linux",
  "source": "$USER_DIR"
}
EOF

echo "[OK] Backup do VS Code criado:"
echo "     $BACKUP_DIR"

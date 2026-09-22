#!/usr/bin/env bash
set -Eeuo pipefail

SHIM="$HOME/.local/bin/devkit"

if [[ ! -e "$SHIM" ]]; then
  echo "[OK] Nenhum shim global do Super Dev Kit encontrado."
  exit 0
fi

if ! grep -q "Super Dev Kit shim" "$SHIM" 2>/dev/null; then
  echo "O arquivo existente não parece ser gerenciado pelo Super Dev Kit:"
  echo "  $SHIM"
  exit 1
fi

rm -f "$SHIM"

echo "[OK] Shim global removido:"
echo "     $SHIM"

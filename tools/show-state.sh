#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/.super-dev-kit/manifest.json"

[[ -f "$MANIFEST" ]] || { echo "Manifesto ainda não existe: $MANIFEST"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq não encontrado."; exit 1; }

echo "================================================"
echo "        SUPER DEV KIT - ESTADO LOCAL"
echo "================================================"
echo

jq -r '
  "Plataforma: (.platform)",
  "Host:       (.host)",
  "Criado:     (.created_at)",
  "Atualizado: (.updated_at)",
  "Perfis:     ((.profiles // []) | join(", "))"
' "$MANIFEST"

echo
echo "Pacotes instalados pelo kit:"
owned_packages="$(jq -r '.packages[] | select(.installed_by_devkit == true) | "  - (.id) [(.manager)] present=(.present)"' "$MANIFEST")"
[[ -n "$owned_packages" ]] && printf '%s
' "$owned_packages" || echo "  (nenhum)"

echo
echo "Extensões VS Code instaladas pelo kit:"
owned_extensions="$(jq -r '.vscode_extensions[] | select(.installed_by_devkit == true) | "  - (.id) present=(.present)"' "$MANIFEST")"
[[ -n "$owned_extensions" ]] && printf '%s
' "$owned_extensions" || echo "  (nenhuma)"

echo
echo "Recursos controlados:"
features="$(jq -r '.features[]? | "  - (.name): present=(.present), by_devkit=(.enabled_by_devkit)"' "$MANIFEST")"
[[ -n "$features" ]] && printf '%s
' "$features" || echo "  (nenhum)"

echo
echo "Arquivo:"
echo "  $MANIFEST"

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
  "Schema:     (.schema_version)",
  "Plataforma: (.platform)",
  "Host:       (.host)",
  "Criado:     (.created_at)",
  "Atualizado: (.updated_at)",
  "Perfis:     ((.profiles // []) | join(", "))",
  "Stacks:     ((.stacks // []) | join(", "))",
  "Módulos:    ((.modules // []) | join(", "))"
' "$MANIFEST"

echo
echo "Runtimes:"
runtime_lines="$(jq -r '
  (.runtime_versions // {})
  | to_entries[]
  | "  - (.key): actual=(.value.actual), desired=(.value.desired), policy=(.value.policy)"
' "$MANIFEST" 2>/dev/null || true)"
[[ -n "$runtime_lines" ]] && printf '%s
' "$runtime_lines" || echo "  (nenhum registrado)"

echo
echo "Pacotes instalados pelo kit:"
owned_packages="$(jq -r '.packages[]? | select(.installed_by_devkit == true) | "  - (.id) [(.manager)] present=(.present)"' "$MANIFEST")"
[[ -n "$owned_packages" ]] && printf '%s
' "$owned_packages" || echo "  (nenhum)"

echo
echo "Extensões VS Code instaladas pelo kit:"
owned_extensions="$(jq -r '.vscode_extensions[]? | select(.installed_by_devkit == true) | "  - (.id) present=(.present)"' "$MANIFEST")"
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

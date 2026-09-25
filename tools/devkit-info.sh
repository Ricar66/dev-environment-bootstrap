#!/usr/bin/env bash
set -Eeuo pipefail

# devkit-info.sh
#
# Purpose:
#   Show a local, read-only summary of the current Super Dev Kit installation.
#
# Side effects:
#   None. The script does not install packages, change configuration or access
#   external services.
#
# Exit codes:
#   0 - summary produced successfully.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
CONFIG_PATH="$ROOT_DIR/config/devkit.config.json"
CONFIG_EXAMPLE_PATH="$ROOT_DIR/config/devkit.config.example.json"
MANIFEST_PATH="$ROOT_DIR/.super-dev-kit/manifest.json"
SHIM_PATH="$HOME/.local/bin/devkit"

version="dev"
[[ -f "$VERSION_FILE" ]] && version="$(tr -d '\r\n' < "$VERSION_FILE")"

branch=""
commit=""
if command -v git >/dev/null 2>&1; then
  branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
fi

platform="Linux"
if [[ -r /etc/os-release ]]; then
  # PRETTY_NAME is provided by the OS and is used only for display.
  platform="$(. /etc/os-release; printf '%s' "${PRETTY_NAME:-Linux}")"
fi

echo "================================================"
echo "          SUPER DEV KIT - INFO"
echo "================================================"
echo
echo "Versão:       $version"
echo "Plataforma:   $platform"
echo "Bash:         ${BASH_VERSION}"
echo "Repositório:  $ROOT_DIR"
[[ -n "$branch" ]] && echo "Branch:       $branch"
[[ -n "$commit" ]] && echo "Commit:       $commit"
echo
echo "Configuração:"
echo "  Local:      $CONFIG_PATH"
if [[ -f "$CONFIG_PATH" ]]; then echo "  Existe:     true"; else echo "  Existe:     false"; fi
echo "  Exemplo:    $CONFIG_EXAMPLE_PATH"
echo
echo "Estado:"
echo "  Manifesto:  $MANIFEST_PATH"

if [[ -f "$MANIFEST_PATH" ]]; then
  echo "  Existe:     true"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$MANIFEST_PATH" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        state = json.load(f)
    print(f"  Schema:     {state.get('schema_version', '')}")
    print("  Perfis:     " + ", ".join(state.get("profiles") or []))
    print("  Stacks:     " + ", ".join(state.get("stacks") or []))
    print("  Módulos:    " + ", ".join(state.get("modules") or []))
except Exception:
    print("  Schema:     invalid")
PY
  fi
else
  echo "  Existe:     false"
fi

echo
echo "CLI global:"
echo "  Shim:       $SHIM_PATH"
if [[ -L "$SHIM_PATH" || -f "$SHIM_PATH" ]]; then echo "  Instalado:  true"; else echo "  Instalado:  false"; fi

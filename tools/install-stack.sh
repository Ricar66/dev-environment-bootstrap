#!/usr/bin/env bash
set -Eeuo pipefail

STACK=""
DRY_RUN=0
SKIP_EXTENSIONS=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/install-stack.sh --stack react
  bash tools/install-stack.sh --stack fullstack-react-node --dry-run

Opções:
  --stack NOME         preset em stacks/NOME.json
  --dry-run            mostra o plano sem alterar a máquina
  --skip-extensions    não instala extensões VS Code
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack)
      STACK="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
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

[[ -n "$STACK" ]] || { usage; exit 1; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT_DIR/modules/catalog.json"
STACK_FILE="$ROOT_DIR/stacks/$STACK.json"
INSTALLER="$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh"
EXTENSIONS_INSTALLER="$ROOT_DIR/tools/install-vscode-extensions.sh"
STATE_HELPER="$ROOT_DIR/tools/state.sh"

if [[ -f "$STATE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_HELPER"
fi

command -v python3 >/dev/null 2>&1 || {
  echo "python3 é necessário para resolver os presets."
  exit 1
}

[[ -f "$CATALOG" ]] || { echo "Catálogo não encontrado: $CATALOG"; exit 1; }

if [[ ! -f "$STACK_FILE" ]]; then
  echo "Stack não encontrada: $STACK"
  echo "Presets disponíveis:"
  find "$ROOT_DIR/stacks" -maxdepth 1 -type f -name '*.json' -printf '  - %f\n' |
    sed 's/\.json$//' |
    sort
  exit 1
fi

PLAN="$(python3 - "$CATALOG" "$STACK_FILE" <<'PY'
import json
import sys

catalog_path, stack_path = sys.argv[1:3]

with open(catalog_path, encoding="utf-8") as f:
    catalog = json.load(f)["modules"]

with open(stack_path, encoding="utf-8") as f:
    stack = json.load(f)

resolved = []

def visit(name):
    if name in resolved:
        return
    module = catalog.get(name)
    if module is None:
        raise SystemExit(f"Módulo inexistente: {name}")
    for dep in module.get("depends_on", []):
        visit(dep)
    if name not in resolved:
        resolved.append(name)

for name in stack.get("modules", []):
    visit(name)

packages = []
extensions = []

for name in resolved:
    module = catalog[name]
    for package in module.get("linux_packages", []):
        if package not in packages:
            packages.append(package)
    for extension in module.get("vscode_extensions", []):
        if extension not in extensions:
            extensions.append(extension)

print("NAME=" + stack["name"])
print("PROFILE=" + stack["base_profile"])
print("MODULES=" + "|".join(resolved))
print("PACKAGES=" + "|".join(packages))
print("EXTENSIONS=" + "|".join(extensions))
print("DESCRIPTION=" + stack.get("description", "").replace("\n", " "))
PY
)"

get_plan() {
  local key="$1"
  printf '%s\n' "$PLAN" | sed -n "s/^$key=//p"
}

NAME="$(get_plan NAME)"
PROFILE="$(get_plan PROFILE)"
MODULES_RAW="$(get_plan MODULES)"
PACKAGES_RAW="$(get_plan PACKAGES)"
EXTENSIONS_RAW="$(get_plan EXTENSIONS)"
DESCRIPTION="$(get_plan DESCRIPTION)"

IFS='|' read -r -a MODULES <<< "$MODULES_RAW"
IFS='|' read -r -a PACKAGES <<< "$PACKAGES_RAW"
IFS='|' read -r -a EXTENSIONS <<< "$EXTENSIONS_RAW"

echo "================================================"
echo "       SUPER DEV KIT - STACK: $NAME"
echo "================================================"
echo
echo "$DESCRIPTION"
echo
echo "Perfil base: $PROFILE"
echo "Módulos:"
printf '  - %s\n' "${MODULES[@]}"

echo
echo "Pacotes extras Linux:"
if [[ -z "$PACKAGES_RAW" ]]; then
  echo "  (nenhum)"
else
  printf '  - %s\n' "${PACKAGES[@]}"
fi

echo
echo "Extensões VS Code:"
if [[ -z "$EXTENSIONS_RAW" ]]; then
  echo "  (nenhuma)"
else
  printf '  - %s\n' "${EXTENSIONS[@]}"
fi

installer_args=(--profile "$PROFILE")

for package in "${PACKAGES[@]}"; do
  [[ -n "$package" ]] && installer_args+=(--package "$package")
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  installer_args+=(--dry-run)
  bash "$INSTALLER" "${installer_args[@]}"
else
  sudo bash "$INSTALLER" "${installer_args[@]}"
fi

if [[ "$SKIP_EXTENSIONS" -ne 1 && -n "$EXTENSIONS_RAW" ]]; then
  extension_args=(--profile essential)

  for extension in "${EXTENSIONS[@]}"; do
    [[ -n "$extension" ]] && extension_args+=(--extension "$extension")
  done

  [[ "$DRY_RUN" -eq 1 ]] && extension_args+=(--dry-run)

  bash "$EXTENSIONS_INSTALLER" "${extension_args[@]}"
fi

echo
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[OK] Plano da stack validado em dry-run."
else
  if declare -F state_add_stack >/dev/null 2>&1; then
    state_add_stack "$STACK" || true

    for module_name in "${MODULES[@]}"; do
      [[ -n "$module_name" ]] && state_add_module "$module_name" || true
    done

    log_event "info" "stack_installed" "$STACK" || true
  fi

  echo "[OK] Stack $NAME processada."
fi

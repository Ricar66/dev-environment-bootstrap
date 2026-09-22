#!/usr/bin/env bash
set -Eeuo pipefail

LOCK_PATH=".super-dev-kit/devkit.lock.json"
DRY_RUN=0
SKIP_EXTENSIONS=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/import-environment.sh
  bash tools/import-environment.sh --lock meu-ambiente.lock.json --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lock)
      LOCK_PATH="${2:-}"
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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT_DIR/modules/catalog.json"
INSTALLER="$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh"
STACK_INSTALLER="$ROOT_DIR/tools/install-stack.sh"
EXTENSIONS_INSTALLER="$ROOT_DIR/tools/install-vscode-extensions.sh"
RUNTIME_CHECKER="$ROOT_DIR/tools/check-runtime-versions.sh"
STATE_HELPER="$ROOT_DIR/tools/state.sh"

if [[ "$LOCK_PATH" != /* ]]; then
  LOCK_PATH="$ROOT_DIR/$LOCK_PATH"
fi

[[ -f "$LOCK_PATH" ]] || { echo "Lock file não encontrado: $LOCK_PATH"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

if [[ -f "$STATE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_HELPER"
fi

PLAN="$(python3 - "$LOCK_PATH" "$CATALOG" <<'PY'
import json
import os
import sys

lock_path, catalog_path = sys.argv[1:3]

with open(lock_path, encoding="utf-8") as f:
    lock = json.load(f)

if lock.get("schema_version") != 1:
    raise SystemExit(f"Schema de lock não suportado: {lock.get('schema_version')}")

catalog = {}
if os.path.exists(catalog_path):
    with open(catalog_path, encoding="utf-8") as f:
        catalog = json.load(f).get("modules", {})

resolved = []

def visit(name):
    if name in resolved:
        return
    module = catalog.get(name)
    if module is None:
        return
    for dep in module.get("depends_on", []):
        visit(dep)
    if name not in resolved:
        resolved.append(name)

for module in lock.get("modules", []):
    visit(module)

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

if not lock.get("stacks") and lock.get("source_platform") == "linux":
    for package in lock.get("packages", {}).get("linux", []):
        if package not in packages:
            packages.append(package)

for extension in lock.get("vscode_extensions", []):
    if extension not in extensions:
        extensions.append(extension)

profiles = lock.get("profiles", [])
profile = profiles[0].lower() if profiles else "essential"
if profile not in {"essential", "frontend", "backend", "fullstack", "datasql", "devops"}:
    profile = "essential"

print("SOURCE=" + str(lock.get("source_platform", "")))
print("DEVKIT_VERSION=" + str(lock.get("devkit_version", "")))
print("PROFILE=" + profile)
print("STACKS=" + "|".join(lock.get("stacks", [])))
print("MODULES=" + "|".join(lock.get("modules", [])))
print("PACKAGES=" + "|".join(packages))
print("EXTENSIONS=" + "|".join(extensions))
PY
)"

get_plan() {
  local key="$1"
  printf '%s\n' "$PLAN" | sed -n "s/^$key=//p"
}

SOURCE="$(get_plan SOURCE)"
LOCK_VERSION="$(get_plan DEVKIT_VERSION)"
PROFILE="$(get_plan PROFILE)"
STACKS_RAW="$(get_plan STACKS)"
MODULES_RAW="$(get_plan MODULES)"
PACKAGES_RAW="$(get_plan PACKAGES)"
EXTENSIONS_RAW="$(get_plan EXTENSIONS)"

IFS='|' read -r -a STACKS <<< "$STACKS_RAW"
IFS='|' read -r -a MODULES <<< "$MODULES_RAW"
IFS='|' read -r -a PACKAGES <<< "$PACKAGES_RAW"
IFS='|' read -r -a EXTENSIONS <<< "$EXTENSIONS_RAW"

echo "================================================"
echo "       SUPER DEV KIT - IMPORT ENVIRONMENT"
echo "================================================"
echo
echo "Lock:          $LOCK_PATH"
echo "Origem:        $SOURCE"
echo "Versão do kit: $LOCK_VERSION"
echo "Perfil base:   $PROFILE"
echo "Stacks:        ${STACKS_RAW:-nenhuma}"
echo "Módulos:       ${MODULES_RAW:-nenhum}"
echo

installed_stack=0

if [[ -n "$STACKS_RAW" ]]; then
  for stack in "${STACKS[@]}"; do
    [[ -n "$stack" ]] || continue

    if [[ ! -f "$ROOT_DIR/stacks/$stack.json" ]]; then
      echo "[AVISO] Stack '$stack' não existe no catálogo atual; usando módulos/pacotes como fallback."
      continue
    fi

    args=(--stack "$stack")
    [[ "$DRY_RUN" -eq 1 ]] && args+=(--dry-run)

    bash "$STACK_INSTALLER" "${args[@]}"
    installed_stack=1
  done
fi

if [[ "$installed_stack" -eq 0 ]]; then
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
fi

if [[ "$SKIP_EXTENSIONS" -ne 1 && -n "$EXTENSIONS_RAW" ]]; then
  extension_args=(--profile essential)

  for extension in "${EXTENSIONS[@]}"; do
    [[ -n "$extension" ]] && extension_args+=(--extension "$extension")
  done

  [[ "$DRY_RUN" -eq 1 ]] && extension_args+=(--dry-run)

  bash "$EXTENSIONS_INSTALLER" "${extension_args[@]}"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  echo "[OK] Import validado em dry-run. Nenhuma alteração foi feita."
  echo "As restrições de runtime serão verificadas após a instalação real."
  exit 0
fi

if declare -F state_add_module >/dev/null 2>&1; then
  for module_name in "${MODULES[@]}"; do
    [[ -n "$module_name" ]] && state_add_module "$module_name" || true
  done

  log_event "info" "environment_imported" "source=$SOURCE,devkit=$LOCK_VERSION" || true
fi

echo
echo "Validando versões de runtime..."

set +e
bash "$RUNTIME_CHECKER" --lock "$LOCK_PATH" --update-manifest
runtime_exit=$?
set -e

if [[ "$runtime_exit" -eq 0 ]]; then
  echo
  echo "[OK] Ambiente importado e runtimes compatíveis com o lock."
else
  echo
  echo "[AVISO] Ambiente importado, mas existem runtimes fora das restrições do lock."
  echo "Use bash tools/compare-environment.sh --lock '$LOCK_PATH' para ver as diferenças."
fi

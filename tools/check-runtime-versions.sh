#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_PATH="config/devkit.config.json"
PRESET=""
LOCK_PATH=""
UPDATE_MANIFEST=0
NO_FAIL=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/check-runtime-versions.sh
  bash tools/check-runtime-versions.sh --preset portable
  bash tools/check-runtime-versions.sh --config config/devkit.config.json --update-manifest
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_PATH="${2:-}"
      shift 2
      ;;
    --preset)
      PRESET="${2:-}"
      shift 2
      ;;
    --lock)
      LOCK_PATH="${2:-}"
      shift 2
      ;;
    --update-manifest)
      UPDATE_MANIFEST=1
      shift
      ;;
    --no-fail)
      NO_FAIL=1
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
CATALOG="$ROOT_DIR/versions/catalog.json"
PRESETS="$ROOT_DIR/versions/presets.json"
STATE_HELPER="$ROOT_DIR/tools/state.sh"

command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

if [[ -f "$STATE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_HELPER"
fi

if [[ "$CONFIG_PATH" != /* ]]; then
  CONFIG_PATH="$ROOT_DIR/$CONFIG_PATH"
fi

if [[ -n "$LOCK_PATH" && "$LOCK_PATH" != /* ]]; then
  LOCK_PATH="$ROOT_DIR/$LOCK_PATH"
fi

if [[ -n "$LOCK_PATH" ]]; then
  SOURCE_MODE="lock"
  [[ -f "$LOCK_PATH" ]] || { echo "Lock file não encontrado: $LOCK_PATH"; exit 1; }
elif [[ -n "$PRESET" ]]; then
  SOURCE_MODE="preset"
else
  SOURCE_MODE="config"
  [[ -f "$CONFIG_PATH" ]] || { echo "Configuração não encontrada: $CONFIG_PATH"; exit 1; }
fi

PLAN="$(python3 - "$CATALOG" "$PRESETS" "$CONFIG_PATH" "$SOURCE_MODE" "$PRESET" "$LOCK_PATH" <<'PY'
import json
import sys

catalog_path, presets_path, config_path, mode, preset_name, lock_path = sys.argv[1:7]

with open(catalog_path, encoding="utf-8") as f:
    catalog = json.load(f)["runtimes"]

if mode == "lock":
    with open(lock_path, encoding="utf-8") as f:
        lock = json.load(f)
    desired = {
        name: value.get("constraint", "")
        for name, value in lock.get("runtime_versions", {}).items()
    }
elif mode == "preset":
    with open(presets_path, encoding="utf-8") as f:
        presets = json.load(f)["presets"]
    if preset_name not in presets:
        raise SystemExit(f"Preset de versões não encontrado: {preset_name}")
    desired = presets[preset_name].get("runtime_versions", {})
else:
    with open(config_path, encoding="utf-8") as f:
        desired = json.load(f).get("runtime_versions", {})

for name, constraint in desired.items():
    if not constraint:
        continue
    runtime = catalog.get(name)
    if runtime is None:
        print(f"UNKNOWN|{name}|{constraint}|||")
        continue
    args = "".join(runtime.get("version_args", []))
    stderr = "1" if runtime.get("stderr_version", False) else "0"
    print("|".join([
        "RUNTIME",
        name,
        str(constraint),
        runtime["linux_command"],
        args,
        stderr
    ]))
PY
)"

if [[ -z "$PLAN" ]]; then
  echo "Nenhuma restrição de runtime configurada."
  exit 0
fi

version_number() {
  printf '%s' "$1" | grep -Eo '[0-9]+([.][0-9]+){0,3}' | head -n 1
}

version_ge() {
  local actual="$1"
  local target="$2"
  [[ "$(printf '%s
%s
' "$target" "$actual" | sort -V | head -n 1)" == "$target" ]]
}

matches_constraint() {
  local actual="$1"
  local constraint="$2"

  if [[ "$constraint" =~ ^major:([0-9]+)$ ]]; then
    [[ "${actual%%.*}" == "${BASH_REMATCH[1]}" ]]
    return
  fi

  if [[ "$constraint" == ">="* ]]; then
    local target="${constraint#>=}"
    version_ge "$actual" "$target"
    return
  fi

  [[ "$actual" == "$constraint" || "$actual" == "$constraint".* ]]
}

echo "================================================"
echo "      SUPER DEV KIT - RUNTIME VERSION CHECK"
echo "================================================"
echo

failures=0

while IFS='|' read -r kind name constraint command_name args_raw stderr_flag; do
  [[ -n "$kind" ]] || continue

  if [[ "$kind" == "UNKNOWN" ]]; then
    echo "[AVISO] Runtime desconhecido no config: $name"
    failures=$((failures + 1))
    continue
  fi

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "[FALHA] $name: não encontrado; esperado $constraint"
    failures=$((failures + 1))
    continue
  fi

  args=()
  if [[ -n "$args_raw" ]]; then
    IFS=$'\x1f' read -r -a args <<< "$args_raw"
  fi

  if [[ "$stderr_flag" == "1" ]]; then
    output="$("$command_name" "${args[@]}" 2>&1 || true)"
  else
    output="$("$command_name" "${args[@]}" || true)"
  fi

  actual="$(version_number "$output")"

  if [[ -z "$actual" ]]; then
    echo "[FALHA] $name: não foi possível detectar a versão."
    failures=$((failures + 1))
    continue
  fi

  if matches_constraint "$actual" "$constraint"; then
    echo "[OK]    $name: $actual atende $constraint"
  else
    echo "[FALHA] $name: $actual não atende $constraint"
    failures=$((failures + 1))
  fi

  if [[ "$UPDATE_MANIFEST" -eq 1 ]] && declare -F state_register_runtime_version >/dev/null 2>&1; then
    state_register_runtime_version "$name" "$constraint" "$actual" "constraint" || true
  fi
done <<< "$PLAN"

echo
if [[ "$failures" -eq 0 ]]; then
  echo "[OK] Todas as restrições configuradas foram atendidas."
  exit 0
fi

echo "$failures runtime(s) fora da política desejada."

if [[ "$NO_FAIL" -eq 1 ]]; then
  exit 0
fi

exit 2

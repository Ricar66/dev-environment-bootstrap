#!/usr/bin/env bash
set -Eeuo pipefail

LOCK_PATH=".super-dev-kit/devkit.lock.json"

usage() {
  cat <<'EOF'
Uso:
  bash tools/compare-environment.sh
  bash tools/compare-environment.sh --lock meu-ambiente.lock.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lock)
      LOCK_PATH="${2:-}"
      shift 2
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
MANIFEST="$ROOT_DIR/.super-dev-kit/manifest.json"
RUNTIME_CHECKER="$ROOT_DIR/tools/check-runtime-versions.sh"

if [[ "$LOCK_PATH" != /* ]]; then
  LOCK_PATH="$ROOT_DIR/$LOCK_PATH"
fi

[[ -f "$LOCK_PATH" ]] || { echo "Lock file não encontrado: $LOCK_PATH"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

echo "================================================"
echo "      SUPER DEV KIT - ENVIRONMENT DIFF"
echo "================================================"
echo
echo "Lock: $LOCK_PATH"
echo

drift_file="$(mktemp)"
trap 'rm -f "$drift_file"' EXIT

python3 - "$LOCK_PATH" "$MANIFEST" "$drift_file" <<'PY'
import json
import os
import sys

lock_path, manifest_path, drift_path = sys.argv[1:4]

with open(lock_path, encoding="utf-8") as f:
    lock = json.load(f)

state = None
if os.path.exists(manifest_path):
    with open(manifest_path, encoding="utf-8") as f:
        state = json.load(f)

drift = []

def add(message):
    if message not in drift:
        drift.append(message)

if state:
    stacks = set(map(str, state.get("stacks", [])))
    modules = set(map(str, state.get("modules", [])))

    for stack in lock.get("stacks", []):
        if str(stack) not in stacks:
            add(f"Stack ausente no manifesto: {stack}")

    for module in lock.get("modules", []):
        if str(module) not in modules:
            add(f"Módulo ausente no manifesto: {module}")
elif lock.get("stacks") or lock.get("modules"):
    add("Manifesto local ausente; stacks/módulos não puderam ser confirmados.")

with open(drift_path, "w", encoding="utf-8") as f:
    for item in drift:
        f.write(item + "\n")
PY

mapfile -t extensions < <(
  python3 - "$LOCK_PATH" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    lock = json.load(f)
for item in lock.get("vscode_extensions", []):
    print(item)
PY
)

if [[ ${#extensions[@]} -gt 0 ]]; then
  if command -v code >/dev/null 2>&1; then
    mapfile -t installed_extensions < <(code --list-extensions 2>/dev/null || true)

    for extension in "${extensions[@]}"; do
      if ! printf '%s\n' "${installed_extensions[@]}" | grep -Fxq "$extension"; then
        echo "Extensão VS Code ausente: $extension" >> "$drift_file"
      fi
    done
  else
    for extension in "${extensions[@]}"; do
      echo "VS Code CLI ausente; extensão não verificável: $extension" >> "$drift_file"
    done
  fi
fi

source_platform="$(python3 - "$LOCK_PATH" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(json.load(f).get("source_platform", ""))
PY
)"

if [[ "$source_platform" == "linux" ]]; then
  mapfile -t packages < <(
    python3 - "$LOCK_PATH" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    lock = json.load(f)
for item in lock.get("packages", {}).get("linux", []):
    print(item)
PY
  )

  for package in "${packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
      echo "Pacote apt ausente: $package" >> "$drift_file"
    fi
  done
fi

echo "Versões de runtime:"

set +e
bash "$RUNTIME_CHECKER" --lock "$LOCK_PATH"
runtime_exit=$?
set -e

if [[ "$runtime_exit" -ne 0 ]]; then
  echo "Uma ou mais versões de runtime não atendem o lock." >> "$drift_file"
fi

echo
echo "Diferenças estruturais:"

mapfile -t drift < <(sort -u "$drift_file")

if [[ ${#drift[@]} -eq 0 ]]; then
  echo "[OK] Nenhuma diferença relevante encontrada."
  exit 0
fi

for item in "${drift[@]}"; do
  [[ -n "$item" ]] && echo "[DRIFT] $item"
done

echo
echo "${#drift[@]} diferença(s) encontrada(s)."
exit 2

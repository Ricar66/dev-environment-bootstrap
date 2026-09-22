#!/usr/bin/env bash
set -Eeuo pipefail

OUTPUT_PATH=".super-dev-kit/devkit.lock.json"
CONFIG_PATH="config/devkit.config.json"

usage() {
  cat <<'EOF'
Uso:
  bash tools/export-environment.sh
  bash tools/export-environment.sh --output meu-ambiente.lock.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --config)
      CONFIG_PATH="${2:-}"
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
VERSION_FILE="$ROOT_DIR/VERSION"

[[ -f "$MANIFEST" ]] || {
  echo "Manifesto não encontrado: $MANIFEST"
  echo "Execute uma instalação do Super Dev Kit antes de exportar."
  exit 1
}

command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

if [[ "$OUTPUT_PATH" != /* ]]; then
  OUTPUT_PATH="$ROOT_DIR/$OUTPUT_PATH"
fi

if [[ "$CONFIG_PATH" != /* ]]; then
  CONFIG_PATH="$ROOT_DIR/$CONFIG_PATH"
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

python3 - "$ROOT_DIR" "$MANIFEST" "$VERSION_FILE" "$CONFIG_PATH" "$OUTPUT_PATH" <<'PY'
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone

root, manifest_path, version_path, config_path, output_path = sys.argv[1:6]

with open(manifest_path, encoding="utf-8") as f:
    state = json.load(f)

desired = {}
if os.path.exists(config_path):
    with open(config_path, encoding="utf-8") as f:
        desired = json.load(f).get("runtime_versions", {}) or {}

def detect(command, args, stderr=False):
    if shutil.which(command) is None:
        return ""
    try:
        proc = subprocess.run(
            [command, *args],
            capture_output=True,
            text=True,
            check=False,
        )
        text = (proc.stderr if stderr else proc.stdout) or proc.stderr or proc.stdout
        match = re.search(r"\d+(?:\.\d+){0,3}", text or "")
        return match.group(0) if match else ""
    except OSError:
        return ""

def default_constraint(name, actual):
    if not actual:
        return ""
    parts = actual.split(".")
    if name in {"python", "php"} and len(parts) >= 2:
        return ".".join(parts[:2])
    return f"major:{parts[0]}"

specs = {
    "node": ("node", ["--version"], False),
    "python": ("python3", ["--version"], False),
    "dotnet": ("dotnet", ["--version"], False),
    "java": ("java", ["-version"], True),
    "php": ("php", ["--version"], False),
}

runtimes = {}
for name, (command, args, stderr) in specs.items():
    actual = detect(command, args, stderr)
    if not actual:
        continue
    constraint = str(desired.get(name) or default_constraint(name, actual))
    runtimes[name] = {
        "actual": actual,
        "constraint": constraint,
    }

packages = sorted({
    str(item.get("id"))
    for item in state.get("packages", [])
    if item.get("manager") == "apt"
    and item.get("installed_by_devkit") is True
    and item.get("present") is True
    and item.get("id")
})

extensions = sorted({
    str(item.get("id"))
    for item in state.get("vscode_extensions", [])
    if item.get("installed_by_devkit") is True
    and item.get("present") is True
    and item.get("id")
})

version = "dev"
if os.path.exists(version_path):
    with open(version_path, encoding="utf-8") as f:
        version = f.read().strip() or "dev"

lock = {
    "schema_version": 1,
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "devkit_version": version,
    "source_platform": "linux",
    "profiles": state.get("profiles", []),
    "stacks": state.get("stacks", []),
    "modules": state.get("modules", []),
    "runtime_versions": runtimes,
    "packages": {
        "windows": [],
        "linux": packages,
    },
    "vscode_extensions": extensions,
}

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(lock, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "[OK] Ambiente exportado:"
echo "     $OUTPUT_PATH"
echo
echo "O lock file não contém senhas, tokens, chaves privadas ou conteúdo de certificados."

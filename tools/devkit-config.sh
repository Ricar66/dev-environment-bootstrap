#!/usr/bin/env bash
set -Eeuo pipefail

# devkit-config.sh
#
# Purpose:
#   Inspect or validate the declarative Super Dev Kit configuration.
#
# Usage:
#   devkit-config.sh <path|show|validate> [--config FILE]
#
# Side effects:
#   None. This helper never creates or changes the configuration.
#
# Exit codes:
#   0 - valid operation / valid configuration
#   1 - configuration file not found
#   2 - invalid JSON or unsupported values
#   64 - invalid command usage
#   69 - python3 unavailable

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION="${1:-}"
shift || true
CONFIG_PATH="config/devkit.config.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      [[ $# -ge 2 ]] || { echo "--config exige um arquivo." >&2; exit 64; }
      CONFIG_PATH="$2"
      shift 2
      ;;
    *)
      echo "Opção desconhecida: $1" >&2
      exit 64
      ;;
  esac
done

case "$ACTION" in
  path|show|validate) ;;
  *)
    echo "Uso: devkit config <path|show|validate> [--config ARQUIVO]" >&2
    exit 64
    ;;
esac

if [[ "$CONFIG_PATH" != /* ]]; then
  CONFIG_PATH="$ROOT_DIR/$CONFIG_PATH"
fi

if [[ "$ACTION" == "path" ]]; then
  echo "$CONFIG_PATH"
  if [[ -f "$CONFIG_PATH" ]]; then echo "Existe: true"; else echo "Existe: false"; fi
  exit 0
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Configuração não encontrada: $CONFIG_PATH" >&2
  echo "Crie a configuração a partir do exemplo:" >&2
  echo "  cp config/devkit.config.example.json config/devkit.config.json" >&2
  exit 1
fi

command -v python3 >/dev/null 2>&1 || {
  echo "python3 é necessário para validar a configuração." >&2
  exit 69
}

if [[ "$ACTION" == "show" ]]; then
  python3 -m json.tool "$CONFIG_PATH"
  exit $?
fi

python3 - "$CONFIG_PATH" <<'PY'
import json
import sys

path = sys.argv[1]

try:
    with open(path, encoding="utf-8") as f:
        config = json.load(f)
except Exception as exc:
    print(f"JSON inválido: {exc}", file=sys.stderr)
    raise SystemExit(2)

errors = []
allowed_profiles = {"essential", "frontend", "backend", "fullstack", "datasql", "devops"}

profile = config.get("profile", "essential")
if not isinstance(profile, str) or profile.lower() not in allowed_profiles:
    errors.append("profile deve ser um de: " + ", ".join(sorted(allowed_profiles)))

for field in ("install_vscode_extensions", "non_interactive"):
    if field in config and not isinstance(config[field], bool):
        errors.append(f"{field} deve ser booleano.")

features = config.get("features", {})
if features is not None and not isinstance(features, dict):
    errors.append("features deve ser um objeto.")
else:
    for field in ("docker", "wsl", "extras"):
        if field in features and not isinstance(features[field], bool):
            errors.append(f"features.{field} deve ser booleano.")

custom = config.get("custom", {})
if custom is not None and not isinstance(custom, dict):
    errors.append("custom deve ser um objeto.")
else:
    for field in ("windows_packages", "linux_packages", "vscode_extensions"):
        if field in custom and not isinstance(custom[field], list):
            errors.append(f"custom.{field} deve ser uma lista.")

runtime_versions = config.get("runtime_versions", {})
if runtime_versions is not None and not isinstance(runtime_versions, dict):
    errors.append("runtime_versions deve ser um objeto.")

if errors:
    print("Configuração inválida:", file=sys.stderr)
    for item in errors:
        print(f"  - {item}", file=sys.stderr)
    raise SystemExit(2)

print(f"[OK] Configuração válida: {path}")
print(f"Perfil: {profile}")
PY

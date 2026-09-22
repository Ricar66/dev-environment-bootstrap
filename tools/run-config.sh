#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_PATH="config/devkit.config.json"
DRY_RUN=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/run-config.sh
  bash tools/run-config.sh --config config/meu-devkit.json
  bash tools/run-config.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_PATH="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
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

if [[ "$CONFIG_PATH" != /* ]]; then
  CONFIG_PATH="$ROOT_DIR/$CONFIG_PATH"
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Configuração não encontrada: $CONFIG_PATH"
  echo "Comece copiando:"
  echo "  cp config/devkit.config.example.json config/devkit.config.json"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 é necessário para ler a configuração JSON."
  echo "Instale com: sudo apt install -y python3"
  exit 1
fi

read_json() {
  local expression="$1"
  python3 - "$CONFIG_PATH" "$expression" <<'PY'
import json
import sys

path, expression = sys.argv[1], sys.argv[2]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

value = data
for part in expression.split("."):
    if not part:
        continue
    if not isinstance(value, dict) or part not in value:
        print("")
        sys.exit(0)
    value = value[part]

if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
else:
    print(value)
PY
}

PROFILE="$(read_json profile)"
PROFILE="${PROFILE:-essential}"
INSTALL_EXTENSIONS="$(read_json install_vscode_extensions)"
CA_AUTO="$(read_json certificate.auto)"
CA_PATH="$(read_json certificate.path)"
GIT_NAME="$(read_json git.name)"
GIT_EMAIL="$(read_json git.email)"

PROFILE="${PROFILE,,}"

case "$PROFILE" in
  essential|frontend|backend|fullstack|datasql|devops) ;;
  *)
    echo "Perfil inválido no JSON: $PROFILE"
    exit 1
    ;;
esac

installer_args=(--profile "$PROFILE")

if [[ "$CA_AUTO" == "true" ]]; then
  installer_args+=(--auto-ca)
elif [[ -n "$CA_PATH" ]]; then
  if [[ "$CA_PATH" != /* ]]; then
    CA_PATH="$ROOT_DIR/$CA_PATH"
  fi
  installer_args+=(--ca "$CA_PATH")
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  installer_args+=(--dry-run)
fi

echo "Configuração: $CONFIG_PATH"
echo "Perfil: $PROFILE"
echo

if [[ "$DRY_RUN" -eq 1 ]]; then
  bash "$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh" "${installer_args[@]}"
else
  sudo bash "$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh" "${installer_args[@]}"
fi

if [[ -n "$GIT_NAME" || -n "$GIT_EMAIL" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    [[ -n "$GIT_NAME" ]] && echo "[DRY-RUN] git config --global user.name \"$GIT_NAME\""
    [[ -n "$GIT_EMAIL" ]] && echo "[DRY-RUN] git config --global user.email \"$GIT_EMAIL\""
    echo "[DRY-RUN] git config --global init.defaultBranch main"
  else
    [[ -n "$GIT_NAME" ]] && git config --global user.name "$GIT_NAME"
    [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch main
  fi
fi

if [[ "$INSTALL_EXTENSIONS" == "true" ]]; then
  ext_args=(--profile "$PROFILE")
  [[ "$DRY_RUN" -eq 1 ]] && ext_args+=(--dry-run)

  bash "$ROOT_DIR/tools/install-vscode-extensions.sh" "${ext_args[@]}"
fi

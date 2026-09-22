#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE="essential"
DRY_RUN=0

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_HELPER="$TOOLS_DIR/state.sh"

if [[ -f "$STATE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_HELPER"
fi

usage() {
  cat <<'EOF'
Uso:
  bash tools/install-vscode-extensions.sh --profile fullstack
  bash tools/install-vscode-extensions.sh --profile datasql --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
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

PROFILE="${PROFILE,,}"

case "$PROFILE" in
  essential|frontend|backend|fullstack|datasql|devops) ;;
  *)
    echo "Perfil inválido: $PROFILE" >&2
    exit 1
    ;;
esac

CODE_AVAILABLE=1

if ! command -v code >/dev/null 2>&1; then
  CODE_AVAILABLE=0

  if [[ "$DRY_RUN" -ne 1 ]]; then
    echo "VS Code CLI ('code') não encontrado no PATH."
    echo "Instale/abra o VS Code e tente novamente."
    exit 1
  fi
fi

base=(
  "EditorConfig.EditorConfig"
  "GitHub.vscode-pull-request-github"
)

frontend=(
  "dbaeumer.vscode-eslint"
  "esbenp.prettier-vscode"
  "bradlc.vscode-tailwindcss"
)

backend=(
  "ms-python.python"
  "ms-python.vscode-pylance"
  "ms-azuretools.vscode-docker"
  "humao.rest-client"
)

datasql=(
  "ms-python.python"
  "ms-python.vscode-pylance"
  "mtxr.sqltools"
  "mtxr.sqltools-driver-mysql"
  "mtxr.sqltools-driver-pg"
)

devops=(
  "ms-azuretools.vscode-docker"
  "redhat.vscode-yaml"
  "ms-vscode-remote.remote-ssh"
)

extensions=("${base[@]}")

case "$PROFILE" in
  frontend)
    extensions+=("${frontend[@]}")
    ;;
  backend)
    extensions+=("${backend[@]}")
    ;;
  fullstack)
    extensions+=("${frontend[@]}" "${backend[@]}")
    ;;
  datasql)
    extensions+=("${datasql[@]}")
    ;;
  devops)
    extensions+=("${devops[@]}")
    ;;
esac

installed=()

if [[ "$CODE_AVAILABLE" -eq 1 ]]; then
  mapfile -t installed < <(code --list-extensions 2>/dev/null || true)
fi

declare -A seen=()

echo "Perfil: $PROFILE"

for extension in "${extensions[@]}"; do
  [[ -n "${seen[$extension]:-}" ]] && continue
  seen["$extension"]=1

  preexisting="false"

  if printf '%s\n' "${installed[@]}" | grep -Fxq "$extension"; then
    preexisting="true"
    echo "[OK] $extension já instalada."

    if [[ "$DRY_RUN" -ne 1 ]] && declare -F state_register_extension >/dev/null 2>&1; then
      state_register_extension "$extension" "true" "true" || true
    fi

    continue
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] code --install-extension $extension"
  else
    echo "[INSTALANDO] $extension"
    code --install-extension "$extension" --force

    present_after="false"
    code --list-extensions 2>/dev/null | grep -Fxq "$extension" && present_after="true"

    if declare -F state_register_extension >/dev/null 2>&1; then
      state_register_extension "$extension" "$preexisting" "$present_after" || true
    fi

    if declare -F log_event >/dev/null 2>&1; then
      log_event "info" "vscode_extension_installed" "$extension" || true
    fi
  fi
done

echo "Concluído."

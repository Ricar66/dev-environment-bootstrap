#!/usr/bin/env bash
set -Eeuo pipefail

APPLY=0
INCLUDE_CORE=0
INCLUDE_DOCKER=0
EXTENSIONS_ONLY=0
PACKAGES_ONLY=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/cleanup.sh
  sudo bash tools/cleanup.sh --apply
  sudo bash tools/cleanup.sh --include-core --apply
  sudo bash tools/cleanup.sh --include-docker --apply

Por segurança, sem --apply o script apenas mostra o que seria removido.

Opções:
  --include-core       inclui ferramentas base instaladas pelo kit
  --include-docker     inclui Docker/Compose instalados pelo kit
  --extensions-only   considera apenas extensões VS Code
  --packages-only     considera apenas pacotes apt
  --apply             executa as remoções
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-core)
      INCLUDE_CORE=1
      shift
      ;;
    --include-docker)
      INCLUDE_DOCKER=1
      shift
      ;;
    --extensions-only)
      EXTENSIONS_ONLY=1
      shift
      ;;
    --packages-only)
      PACKAGES_ONLY=1
      shift
      ;;
    --apply)
      APPLY=1
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

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$TOOLS_DIR/.." && pwd)"
MANIFEST="$ROOT_DIR/.super-dev-kit/manifest.json"
STATE_HELPER="$TOOLS_DIR/state.sh"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifesto não encontrado: $MANIFEST"
  echo "Execute uma instalação v0.4+ primeiro."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq é necessário para ler o manifesto."
  exit 1
fi

if [[ -f "$STATE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_HELPER"
fi

core_regex='^(ca-certificates|curl|wget|git|unzip|zip|nano|vim|htop|tree|jq|openssl|gnupg|lsb-release|software-properties-common|net-tools|iproute2|iputils-ping|dnsutils|traceroute|build-essential|openssh-server|virtualbox-guest-utils|virtualbox-guest-x11)$'
docker_regex='^(docker.io|docker-compose-v2|docker-compose-plugin|docker-compose)$'

mapfile -t packages < <(
  jq -r '.packages[]
    | select(.manager == "apt" and .installed_by_devkit == true and .present == true)
    | .id' "$MANIFEST"
)

filtered_packages=()

for pkg in "${packages[@]}"; do
  [[ -n "$pkg" ]] || continue

  if [[ "$INCLUDE_CORE" -ne 1 && "$pkg" =~ $core_regex ]]; then
    continue
  fi

  if [[ "$INCLUDE_DOCKER" -ne 1 && "$pkg" =~ $docker_regex ]]; then
    continue
  fi

  filtered_packages+=("$pkg")
done

packages=("${filtered_packages[@]}")

mapfile -t extensions < <(
  jq -r '.vscode_extensions[]
    | select(.installed_by_devkit == true and .present == true)
    | .id' "$MANIFEST"
)

[[ "$EXTENSIONS_ONLY" -eq 1 ]] && packages=()
[[ "$PACKAGES_ONLY" -eq 1 ]] && extensions=()

echo "================================================"
echo "       SUPER DEV KIT - MANIFEST CLEANUP"
echo "================================================"
echo

echo "Pacotes registrados como instalados pelo kit:"
if [[ ${#packages[@]} -eq 0 ]]; then
  echo "  (nenhum selecionado)"
else
  printf '  - %s\n' "${packages[@]}"
fi

echo
echo "Extensões VS Code registradas como instaladas pelo kit:"
if [[ ${#extensions[@]} -eq 0 ]]; then
  echo "  (nenhuma)"
else
  printf '  - %s\n' "${extensions[@]}"
fi

echo
echo "Proteções ativas:"
[[ "$INCLUDE_CORE" -ne 1 ]] && echo "  - ferramentas core preservadas"
[[ "$INCLUDE_DOCKER" -ne 1 ]] && echo "  - Docker/Compose preservados"
echo "  - itens preexistentes não são removidos"
echo "  - certificado CA, grupos, imagens e volumes Docker não são removidos"

if [[ "$APPLY" -ne 1 ]]; then
  echo
  echo "[PREVIEW] Nenhuma alteração foi feita."
  echo
  echo "Para aplicar:"
  echo "  sudo bash tools/cleanup.sh --apply"
  exit 0
fi

if [[ ${#packages[@]} -gt 0 && "$EUID" -ne 0 ]]; then
  echo "Use sudo ao aplicar remoção de pacotes."
  exit 1
fi

read -r -p "Digite REMOVER para confirmar: " confirm

if [[ "$confirm" != "REMOVER" ]]; then
  echo "Operação cancelada."
  exit 0
fi

TARGET_USER="${SUDO_USER:-$USER}"

for extension in "${extensions[@]}"; do
  [[ -n "$extension" ]] || continue

  echo "[REMOVENDO EXTENSÃO] $extension"

  if [[ "$EUID" -eq 0 && "$TARGET_USER" != "root" ]]; then
    sudo -u "$TARGET_USER" -H bash -lc       "command -v code >/dev/null 2>&1 && code --uninstall-extension '$extension'" || true

    present_after="false"
    if sudo -u "$TARGET_USER" -H bash -lc       "command -v code >/dev/null 2>&1 && code --list-extensions | grep -Fxq '$extension'"; then
      present_after="true"
    fi
  else
    command -v code >/dev/null 2>&1 && code --uninstall-extension "$extension" || true

    present_after="false"
    if command -v code >/dev/null 2>&1 &&
      code --list-extensions 2>/dev/null | grep -Fxq "$extension"; then
      present_after="true"
    fi
  fi

  if declare -F state_register_extension >/dev/null 2>&1; then
    state_register_extension "$extension" "false" "$present_after" || true
  fi
done

if [[ ${#packages[@]} -gt 0 ]]; then
  apt-get remove -y "${packages[@]}"
  apt-get autoremove -y

  for pkg in "${packages[@]}"; do
    present_after="false"

    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
      present_after="true"
    fi

    if declare -F state_register_package >/dev/null 2>&1; then
      state_register_package "$pkg" "$pkg" "apt" "false" "$present_after" || true
    fi
  done
fi

if declare -F log_event >/dev/null 2>&1; then
  log_event "info" "cleanup_completed" "packages=${#packages[@]},extensions=${#extensions[@]}" || true
fi

echo
echo "[OK] Cleanup concluído."
echo "O manifesto foi atualizado com o estado atual."

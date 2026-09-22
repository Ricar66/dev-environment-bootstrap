#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Super Dev Kit - Ubuntu bootstrap
#
# Exemplos:
#   sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack
#   bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --dry-run
#   sudo bash linux/bootstrap-vm-ubuntu.sh --profile datasql --package redis-tools
#   sudo bash linux/bootstrap-vm-ubuntu.sh --auto-ca --yes
# ============================================================

CURRENT_USER="${USER:-$(id -un 2>/dev/null || echo root)}"
ORIGINAL_USER="${SUDO_USER:-$CURRENT_USER}"
PROFILE="essential"
CA_FILE=""
AUTO_CA=0
DRY_RUN=0
YES=0
CUSTOM_PACKAGES=()

usage() {
  cat <<'EOF'
Uso:
  sudo bash linux/bootstrap-vm-ubuntu.sh [opções]

Opções:
  --profile PERFIL   essential | frontend | backend | fullstack | datasql | devops
  --ca ARQUIVO       instala um certificado CA .cer/.crt
  --auto-ca          procura certificados em Downloads, /media e /mnt
  --package PACOTE   adiciona um pacote apt customizado (pode repetir)
  --dry-run          mostra o plano sem alterar a máquina
  --yes              modo não interativo para confirmações suportadas
  -h, --help         mostra esta ajuda
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --ca)
      CA_FILE="${2:-}"
      shift 2
      ;;
    --auto-ca)
      AUTO_CA=1
      shift
      ;;
    --package)
      CUSTOM_PACKAGES+=("${2:-}")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --yes|--non-interactive)
      YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Opção desconhecida: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -z "$CA_FILE" ]]; then
        CA_FILE="$1"
        shift
      else
        echo "Argumento inesperado: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

PROFILE="${PROFILE,,}"

case "$PROFILE" in
  essential|frontend|backend|fullstack|datasql|devops) ;;
  *)
    echo "Perfil inválido: $PROFILE" >&2
    usage
    exit 1
    ;;
esac

log() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

fail() {
  echo "ERRO: $1" >&2
  exit 1
}

pkg_installed() {
  local pkg="$1"
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

if [[ "$DRY_RUN" -ne 1 ]]; then
  [[ "${EUID}" -eq 0 ]] || fail "Execute com sudo: sudo bash $0"
fi

command -v apt-get >/dev/null 2>&1 || fail "Este script requer apt (Ubuntu/Debian)."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CA_HELPER="$REPO_ROOT/certificates/import-ca-linux.sh"
STATE_HELPER="$REPO_ROOT/tools/state.sh"

if [[ -f "$STATE_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$STATE_HELPER"
fi

install_apt_packages() {
  local packages=("$@")
  local pkg
  declare -A preexisting=()

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi

  for pkg in "${packages[@]}"; do
    [[ -n "$pkg" ]] || continue

    if pkg_installed "$pkg"; then
      preexisting["$pkg"]="true"
    else
      preexisting["$pkg"]="false"
    fi
  done

  DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"

  for pkg in "${packages[@]}"; do
    [[ -n "$pkg" ]] || continue

    local present_after="false"
    pkg_installed "$pkg" && present_after="true"

    if declare -F state_register_package >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      state_register_package         "$pkg"         "$pkg"         "apt"         "${preexisting[$pkg]:-false}"         "$present_after"
    fi
  done
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "============================================================"
  echo "SUPER DEV KIT - DRY RUN"
  echo "============================================================"
  echo "Perfil: $PROFILE"
  echo "Certificado informado: ${CA_FILE:-nenhum}"
  echo "Busca automática de CA: $AUTO_CA"
  echo
  echo "Pacotes base:"
  echo "  ca-certificates curl wget git unzip zip nano vim htop tree jq"
  echo "  openssl gnupg lsb-release software-properties-common"
  echo "  net-tools iproute2 iputils-ping dnsutils traceroute build-essential"
  echo "  openssh-server docker.io"
  echo
  echo "Pacotes do perfil:"

  case "$PROFILE" in
    essential|devops)
      echo "  (nenhum adicional)"
      ;;
    frontend)
      echo "  nodejs npm"
      ;;
    backend|fullstack)
      echo "  nodejs npm python3 python3-pip python3-venv sqlite3"
      ;;
    datasql)
      echo "  python3 python3-pip python3-venv sqlite3 postgresql-client default-mysql-client"
      ;;
  esac

  if [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then
    echo
    echo "Pacotes customizados:"
    printf '  %s\n' "${CUSTOM_PACKAGES[@]}"
  fi

  echo
  echo "Outras ações planejadas:"
  echo "  - registrar estado local no manifesto .super-dev-kit/manifest.json"
  echo "  - habilitar SSH"
  echo "  - instalar/validar Docker Compose"
  echo "  - adicionar usuário ao grupo docker"
  echo "  - configurar VirtualBox Guest Utilities se aplicável"
  echo "  - testar HTTPS e hello-world"
  [[ "$AUTO_CA" -eq 1 ]] && echo "  - procurar e importar CA corporativa"
  [[ -n "$CA_FILE" ]] && echo "  - validar/importar CA: $CA_FILE"
  echo
  echo "Nenhuma alteração foi feita."
  exit 0
fi

log "[1/11] Informações do sistema"
echo "Usuário: $ORIGINAL_USER"
echo "Hostname: $(hostname)"
echo "Perfil: $PROFILE"
grep -E '^(NAME|VERSION|VERSION_CODENAME)=' /etc/os-release || true
echo "Virtualização: $(systemd-detect-virt 2>/dev/null || echo desconhecida)"

log "[2/11] Verificando estado do gerenciador de pacotes"
AUDIT="$(dpkg --audit 2>/dev/null || true)"

if [[ -n "$AUDIT" ]]; then
  echo "Foram encontrados pacotes pendentes:"
  echo "$AUDIT"
  echo
  echo "Tentando reparar dependências..."
  DEBIAN_FRONTEND=noninteractive apt-get -f install -y
  dpkg --configure -a
else
  echo "dpkg sem pendências detectadas."
fi

log "[3/11] Atualizando repositórios"
apt-get update

log "[4/11] Instalando ferramentas essenciais"
install_apt_packages   ca-certificates curl wget git unzip zip nano vim htop tree jq   openssl gnupg lsb-release software-properties-common   net-tools iproute2 iputils-ping dnsutils traceroute build-essential

if declare -F ensure_state >/dev/null 2>&1; then
  ensure_state || true
  state_add_profile "$PROFILE" || true
  log_event "info" "setup_started" "profile=$PROFILE" || true
fi

log "[5/11] Instalando ferramentas do perfil: $PROFILE"

case "$PROFILE" in
  essential|devops)
    echo "Nenhum pacote adicional necessário para este perfil."
    ;;
  frontend)
    install_apt_packages nodejs npm
    ;;
  backend|fullstack)
    install_apt_packages nodejs npm python3 python3-pip python3-venv sqlite3
    ;;
  datasql)
    install_apt_packages       python3 python3-pip python3-venv sqlite3       postgresql-client default-mysql-client
    ;;
esac

if [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then
  log "Pacotes customizados"
  install_apt_packages "${CUSTOM_PACKAGES[@]}"
fi

log "[6/11] Certificados"
update-ca-certificates

CA_DEST="/usr/local/share/ca-certificates/super-dev-kit-local-ca.crt"
CA_PREEXISTING="false"
[[ -f "$CA_DEST" ]] && CA_PREEXISTING="true"

if [[ "$AUTO_CA" -eq 1 ]]; then
  if [[ -f "$CA_HELPER" ]]; then
    if [[ "$YES" -eq 1 ]]; then
      bash "$CA_HELPER" --auto --yes
    else
      bash "$CA_HELPER" --auto
    fi
  else
    echo "Importador automático não encontrado: $CA_HELPER"
  fi
elif [[ -n "$CA_FILE" ]]; then
  [[ -f "$CA_FILE" ]] || fail "Certificado não encontrado: $CA_FILE"

  TMP_PEM="$(mktemp)"
  trap 'rm -f "$TMP_PEM"' EXIT

  if openssl x509 -in "$CA_FILE" -noout >/dev/null 2>&1; then
    cp "$CA_FILE" "$TMP_PEM"
  elif openssl x509 -inform DER -in "$CA_FILE" -noout >/dev/null 2>&1; then
    openssl x509 -inform DER -in "$CA_FILE" -out "$TMP_PEM"
  else
    fail "O arquivo informado não parece ser um certificado X.509 válido."
  fi

  echo "Certificado selecionado:"
  openssl x509 -in "$TMP_PEM" -noout -subject -issuer -fingerprint -sha256

  install -m 0644 "$TMP_PEM" "$CA_DEST"
  update-ca-certificates
  echo "CA adicionada em: $CA_DEST"
else
  echo "Nenhum certificado CA adicional informado."
  echo "Isso é normal para a maioria das redes."
fi

if declare -F state_register_feature >/dev/null 2>&1; then
  CA_PRESENT="false"
  [[ -f "$CA_DEST" ]] && CA_PRESENT="true"
  state_register_feature "corporate_ca" "$CA_PREEXISTING" "$CA_PRESENT" || true
fi

log "[7/11] SSH"
install_apt_packages openssh-server
systemctl enable --now ssh

log "[8/11] Docker"
install_apt_packages docker.io
systemctl enable --now docker

if docker compose version >/dev/null 2>&1; then
  echo "Docker Compose já está disponível; mantendo a implementação instalada."
elif pkg_installed docker-compose-plugin; then
  echo "docker-compose-plugin já está instalado; não instalando docker-compose-v2."
  if declare -F state_register_package >/dev/null 2>&1; then
    state_register_package "docker-compose-plugin" "docker-compose-plugin" "apt" "true" "true" || true
  fi
elif pkg_installed docker-compose-v2; then
  echo "docker-compose-v2 já está instalado."
  if declare -F state_register_package >/dev/null 2>&1; then
    state_register_package "docker-compose-v2" "docker-compose-v2" "apt" "true" "true" || true
  fi
elif apt-cache show docker-compose-v2 >/dev/null 2>&1; then
  install_apt_packages docker-compose-v2
elif apt-cache show docker-compose-plugin >/dev/null 2>&1; then
  install_apt_packages docker-compose-plugin
elif apt-cache show docker-compose >/dev/null 2>&1; then
  install_apt_packages docker-compose
else
  echo "AVISO: nenhum pacote Docker Compose compatível foi encontrado."
fi

log "[9/11] Permissões e VirtualBox"

DOCKER_GROUP_PREEXISTING="false"

if id -nG "$ORIGINAL_USER" 2>/dev/null | grep -qw docker; then
  DOCKER_GROUP_PREEXISTING="true"
fi

if id "$ORIGINAL_USER" >/dev/null 2>&1 && getent group docker >/dev/null 2>&1; then
  usermod -aG docker "$ORIGINAL_USER"
  echo "Usuário '$ORIGINAL_USER' adicionado ao grupo docker."
fi

if declare -F state_register_feature >/dev/null 2>&1; then
  state_register_feature "docker_group" "$DOCKER_GROUP_PREEXISTING" "true" || true
fi

VIRT="$(systemd-detect-virt 2>/dev/null || true)"

if [[ "$VIRT" == "oracle" ]] || grep -qi "VirtualBox" /sys/class/dmi/id/product_name 2>/dev/null; then
  echo "VirtualBox detectado."

  if apt-cache show virtualbox-guest-utils >/dev/null 2>&1; then
    install_apt_packages virtualbox-guest-utils
  fi

  if systemctl get-default 2>/dev/null | grep -q graphical; then
    if apt-cache show virtualbox-guest-x11 >/dev/null 2>&1; then
      install_apt_packages virtualbox-guest-x11
    fi
  fi

  VBOXSF_PREEXISTING="false"
  id -nG "$ORIGINAL_USER" 2>/dev/null | grep -qw vboxsf && VBOXSF_PREEXISTING="true"

  if getent group vboxsf >/dev/null 2>&1 && id "$ORIGINAL_USER" >/dev/null 2>&1; then
    usermod -aG vboxsf "$ORIGINAL_USER"
    echo "Usuário '$ORIGINAL_USER' adicionado ao grupo vboxsf."

    if declare -F state_register_feature >/dev/null 2>&1; then
      state_register_feature "vboxsf_group" "$VBOXSF_PREEXISTING" "true" || true
    fi
  fi
else
  echo "VirtualBox não detectado; etapa ignorada."
fi

log "[10/11] Diagnóstico"
echo "IPs: $(hostname -I 2>/dev/null || true)"
echo "SSH: $(systemctl is-active ssh || true)"
echo "Docker: $(systemctl is-active docker || true)"
docker --version || true

if docker compose version >/dev/null 2>&1; then
  docker compose version
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose --version
fi

case "$PROFILE" in
  frontend|backend|fullstack)
    node --version 2>/dev/null || true
    npm --version 2>/dev/null || true
    ;;
esac

case "$PROFILE" in
  backend|fullstack|datasql)
    python3 --version 2>/dev/null || true
    ;;
esac

echo
echo "Teste HTTPS do Docker Hub:"
set +e
HTTP_CODE="$(curl -sS -o /tmp/docker-registry-response.txt -w "%{http_code}"   https://registry-1.docker.io/v2/ 2>/tmp/docker-registry-error.txt)"
CURL_RC=$?
set -e

if [[ $CURL_RC -eq 0 ]]; then
  echo "HTTPS OK (HTTP $HTTP_CODE)."
else
  cat /tmp/docker-registry-error.txt || true
  echo
  echo "Possível inspeção HTTPS por proxy/firewall."
  echo "Emissor apresentado pela rede:"
  curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -Ei 'issuer:|subject:' || true
  echo
  echo "Se necessário, use:"
  echo "  sudo bash certificates/import-ca-linux.sh --auto"
fi

log "[11/11] Teste de container"

if docker run --rm hello-world; then
  echo "SUCESSO: Docker funcional."
else
  echo "O Docker foi instalado, mas o hello-world falhou."
  echo "Se houver erro x509/self-signed/unknown authority, consulte:"
  echo "  docs/CERTIFICADOS-CORPORATIVOS.md"
fi

if declare -F log_event >/dev/null 2>&1; then
  log_event "info" "setup_completed" "profile=$PROFILE" || true
fi

echo
echo "Concluído."
echo "Perfil instalado: $PROFILE"
echo "Manifesto local: $REPO_ROOT/.super-dev-kit/manifest.json"
echo
echo "IMPORTANTE:"
echo "Faça logout/login, execute 'newgrp docker' ou reinicie a VM"
echo "para ativar completamente os grupos docker/vboxsf."

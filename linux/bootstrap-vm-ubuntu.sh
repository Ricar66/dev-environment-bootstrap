#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# bootstrap-vm-ubuntu.sh
# Prepara uma VM Ubuntu para estudos/desenvolvimento.
#
# Instala/configura:
# - Certificados CA
# - SSH Server
# - Git e utilitários
# - Ferramentas de rede/compilação
# - Docker e Docker Compose (quando disponível)
# - VirtualBox Guest Utilities (se VirtualBox for detectado)
# - Usuário nos grupos docker e vboxsf
#
# Uso:
#   sudo bash bootstrap-vm-ubuntu.sh
#
# Com certificado corporativo:
#   sudo bash bootstrap-vm-ubuntu.sh /caminho/certificado.cer
# ============================================================

ORIGINAL_USER="${SUDO_USER:-$USER}"
CA_FILE="${1:-}"

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

[[ "${EUID}" -eq 0 ]] || fail "Execute com sudo: sudo bash $0"
command -v apt-get >/dev/null 2>&1 || fail "Este script requer apt (Ubuntu/Debian)."

log "[1/10] Informações do sistema"
echo "Usuário: $ORIGINAL_USER"
echo "Hostname: $(hostname)"
grep -E '^(NAME|VERSION|VERSION_CODENAME)=' /etc/os-release || true
echo "Virtualização: $(systemd-detect-virt 2>/dev/null || echo desconhecida)"

log "[2/10] Atualizando repositórios"
apt-get update

log "[3/10] Instalando ferramentas essenciais"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl wget git unzip zip nano vim htop tree jq \
  openssl gnupg lsb-release software-properties-common \
  net-tools iproute2 iputils-ping dnsutils traceroute build-essential

log "[4/10] Certificados"
update-ca-certificates

if [[ -n "$CA_FILE" ]]; then
  [[ -f "$CA_FILE" ]] || fail "Certificado não encontrado: $CA_FILE"

  DEST_CA="/usr/local/share/ca-certificates/rede-local-ca.crt"
  cp "$CA_FILE" "$DEST_CA"
  chmod 0644 "$DEST_CA"
  update-ca-certificates
  echo "CA adicionada em: $DEST_CA"
else
  echo "Nenhum certificado CA adicional informado."
fi

log "[5/10] SSH"
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
systemctl enable --now ssh

log "[6/10] Docker"
DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io
systemctl enable --now docker

# Evita conflito entre docker-compose-v2 (Ubuntu) e docker-compose-plugin
# (repositório oficial da Docker). Se "docker compose" já funciona, não instala
# outro pacote concorrente.
if docker compose version >/dev/null 2>&1; then
  echo "Docker Compose já está disponível; mantendo a implementação instalada."
elif dpkg-query -W -f='${Status}' docker-compose-plugin 2>/dev/null | grep -q "install ok installed"; then
  echo "docker-compose-plugin já está instalado; não instalando docker-compose-v2."
elif dpkg-query -W -f='${Status}' docker-compose-v2 2>/dev/null | grep -q "install ok installed"; then
  echo "docker-compose-v2 já está instalado."
elif apt-cache show docker-compose-v2 >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose-v2
elif apt-cache show docker-compose-plugin >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose-plugin
elif apt-cache show docker-compose >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose
else
  echo "AVISO: nenhum pacote Docker Compose compatível foi encontrado."
fi

log "[7/10] Permissões"

if id "$ORIGINAL_USER" >/dev/null 2>&1 && getent group docker >/dev/null 2>&1; then
  usermod -aG docker "$ORIGINAL_USER"
  echo "Usuário adicionado ao grupo docker."
fi

log "[8/10] VirtualBox"
VIRT="$(systemd-detect-virt 2>/dev/null || true)"

if [[ "$VIRT" == "oracle" ]] || grep -qi "VirtualBox" /sys/class/dmi/id/product_name 2>/dev/null; then
  echo "VirtualBox detectado."

  if apt-cache show virtualbox-guest-utils >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y virtualbox-guest-utils
  fi

  if systemctl get-default 2>/dev/null | grep -q graphical; then
    if apt-cache show virtualbox-guest-x11 >/dev/null 2>&1; then
      DEBIAN_FRONTEND=noninteractive apt-get install -y virtualbox-guest-x11
    fi
  fi

  if getent group vboxsf >/dev/null 2>&1 && id "$ORIGINAL_USER" >/dev/null 2>&1; then
    usermod -aG vboxsf "$ORIGINAL_USER"
  fi
else
  echo "VirtualBox não detectado; etapa ignorada."
fi

log "[9/10] Diagnóstico"
echo "IPs: $(hostname -I 2>/dev/null || true)"
echo "SSH: $(systemctl is-active ssh || true)"
echo "Docker: $(systemctl is-active docker || true)"
docker --version || true

if docker compose version >/dev/null 2>&1; then
  docker compose version
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose --version
fi

echo
echo "Teste HTTPS do Docker Hub:"
set +e
HTTP_CODE="$(curl -sS -o /tmp/docker-registry-response.txt -w "%{http_code}" \
  https://registry-1.docker.io/v2/ 2>/tmp/docker-registry-error.txt)"
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
fi

log "[10/10] Teste de container"

if docker run --rm hello-world; then
  echo "SUCESSO: Docker funcional."
else
  echo "O Docker foi instalado, mas o hello-world falhou."
  echo "Se houver erro x509/self-signed/unknown authority, consulte:"
  echo "  docs/CERTIFICADOS-CORPORATIVOS.md"
fi

echo
echo "Concluído."
echo "Reinicie ou faça logout/login para ativar completamente os grupos docker/vboxsf."

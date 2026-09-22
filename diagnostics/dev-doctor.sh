#!/usr/bin/env bash
set -u

OK='[OK]'
WARN='[AVISO]'

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '%-10s %-18s %s\n' "$OK" "$cmd" "$(command -v "$cmd")"
  else
    printf '%-10s %-18s %s\n' "$WARN" "$cmd" "não encontrado"
  fi
}

echo "========================================="
echo "          SUPER DEV KIT - DOCTOR"
echo "========================================="
echo

printf 'Sistema: '
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  echo "${PRETTY_NAME:-Linux}"
else
  uname -a
fi

printf 'Hostname: '
hostname

printf 'IPs: '
hostname -I 2>/dev/null || true

echo

for cmd in git node npm docker curl wget ssh code jq; do
  check_cmd "$cmd"
done

echo

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "$OK Docker daemon acessível."
  else
    echo "$WARN Docker instalado, mas o daemon/permissão precisa ser verificado."
  fi
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
  echo "$OK SSH ativo."
else
  echo "$WARN SSH não está ativo ou systemd não está disponível."
fi

echo

if curl -sS --max-time 10 https://registry-1.docker.io/v2/ >/dev/null 2>&1; then
  echo "$OK TLS/HTTPS do Docker Hub respondeu."
else
  echo "$WARN Falha no teste HTTPS do Docker Hub. Verifique rede/proxy/certificados."
fi

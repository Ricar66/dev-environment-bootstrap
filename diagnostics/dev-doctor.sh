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

echo "=============================================="
echo "          SUPER DEV KIT - DEV DOCTOR"
echo "=============================================="
echo

printf 'Sistema: '
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  echo "${PRETTY_NAME:-Linux}"
else
  uname -a
fi

echo "Kernel: $(uname -r)"
echo "Hostname: $(hostname)"
echo "IPs: $(hostname -I 2>/dev/null || true)"
echo

echo "--- Ferramentas ---"
for cmd in git node npm python3 docker curl wget ssh code jq; do
  check_cmd "$cmd"
done

echo
echo "--- Recursos ---"
df -h / | tail -n 1 || true
free -h 2>/dev/null | sed -n '1,2p' || true

echo
echo "--- Docker ---"

if command -v docker >/dev/null 2>&1; then
  docker --version || true

  if docker info >/dev/null 2>&1; then
    echo "$OK Docker daemon acessível para o usuário atual."
  else
    echo "$WARN Docker instalado, mas daemon/permissão precisa ser verificado."
    echo "        Tente: sudo usermod -aG docker \$USER && newgrp docker"
  fi

  if docker compose version >/dev/null 2>&1; then
    echo "$OK $(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "$OK $(docker-compose --version)"
  else
    echo "$WARN Docker Compose não encontrado."
  fi

  echo "Pacotes Compose detectados:"
  dpkg-query -W -f='  ${Package}: ${Status}\n' docker-compose-v2 docker-compose-plugin docker-compose 2>/dev/null || true
else
  echo "$WARN Docker não encontrado."
fi

echo
echo "--- Grupos ---"

if id -nG "$USER" | grep -qw docker; then
  echo "$OK Usuário pertence ao grupo docker."
else
  echo "$WARN Usuário ainda não pertence ao grupo docker."
fi

if getent group vboxsf >/dev/null 2>&1; then
  if id -nG "$USER" | grep -qw vboxsf; then
    echo "$OK Usuário pertence ao grupo vboxsf."
  else
    echo "$WARN Grupo vboxsf existe, mas o usuário não pertence a ele."
  fi
fi

echo
echo "--- SSH ---"

if systemctl is-active --quiet ssh 2>/dev/null; then
  echo "$OK SSH ativo."
else
  echo "$WARN SSH não está ativo ou systemd não está disponível."
fi

echo
echo "--- Pastas compartilhadas VirtualBox ---"
if compgen -G "/media/sf_*" >/dev/null; then
  printf '%s\n' /media/sf_*
else
  echo "Nenhuma pasta /media/sf_* encontrada."
fi

echo
echo "--- HTTPS / Docker Hub ---"
TMP_BODY="$(mktemp)"
TMP_ERR="$(mktemp)"
trap 'rm -f "$TMP_BODY" "$TMP_ERR"' EXIT

set +e
HTTP_CODE="$(curl -sS --max-time 10 -o "$TMP_BODY" -w "%{http_code}" https://registry-1.docker.io/v2/ 2>"$TMP_ERR")"
CURL_RC=$?
set -e

if [[ $CURL_RC -eq 0 ]]; then
  echo "$OK TLS/HTTPS respondeu. HTTP $HTTP_CODE."
else
  echo "$WARN Falha TLS/HTTPS:"
  cat "$TMP_ERR"
  echo
  echo "Emissor apresentado pela rede:"
  curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -Ei 'issuer:|subject:' || true
  echo
  echo "Se for uma CA corporativa autorizada:"
  echo "  sudo bash certificates/import-ca-linux.sh --auto"
fi

echo
echo "Diagnóstico concluído."

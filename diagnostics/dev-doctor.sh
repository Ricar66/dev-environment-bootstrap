#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/.super-dev-kit/manifest.json"
CURRENT_USER="${USER:-$(id -un 2>/dev/null || echo root)}"

TOTAL=0
PASSED=0
WARNINGS=0
FAILED=0

add_check() {
  local category="$1"
  local name="$2"
  local status="$3"
  local detail="${4:-}"
  local hint="${5:-}"
  local label

  if [[ "$status" != "SKIP" ]]; then
    TOTAL=$((TOTAL + 1))
  fi

  case "$status" in
    PASS)
      PASSED=$((PASSED + 1))
      label="[OK]"
      ;;
    WARN)
      WARNINGS=$((WARNINGS + 1))
      label="[AVISO]"
      ;;
    FAIL)
      FAILED=$((FAILED + 1))
      label="[FALHA]"
      ;;
    SKIP)
      label="[SKIP]"
      ;;
  esac

  printf '%-9s %-12s %s\n' "$label" "$category" "$name"

  [[ -n "$detail" ]] && printf '          %s\n' "$detail"

  if [[ -n "$hint" && ( "$status" == "WARN" || "$status" == "FAIL" ) ]]; then
    printf '          Sugestão: %s\n' "$hint"
  fi
}

echo "================================================"
echo "       SUPER DEV KIT - DEV DOCTOR v2"
echo "================================================"
echo

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  echo "Sistema: ${PRETTY_NAME:-Linux}"
else
  echo "Sistema: $(uname -s)"
fi

echo "Kernel:  $(uname -r)"
echo "Host:    $(hostname)"
echo

available_kb="$(df -Pk / | awk 'NR==2 {print $4}')"

if [[ "$available_kb" =~ ^[0-9]+$ ]] && (( available_kb > 5242880 )); then
  add_check "Sistema" "Espaço em disco" "PASS" "$(df -h / | awk 'NR==2 {print $4 " livres"}')"
else
  add_check "Sistema" "Espaço em disco" "WARN" "$(df -h / | awk 'NR==2 {print $4 " livres"}')" "Mantenha pelo menos 5 GB livres."
fi

for cmd in git curl jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    add_check "Core" "$cmd" "PASS" "$(command -v "$cmd")"
  else
    add_check "Core" "$cmd" "FAIL" "" "Instale o pacote e confirme o PATH."
  fi
done

for cmd in node npm python3 code; do
  if command -v "$cmd" >/dev/null 2>&1; then
    add_check "Runtime" "$cmd" "PASS" "$(command -v "$cmd")"
  else
    add_check "Runtime" "$cmd" "SKIP" "Não instalado neste ambiente."
  fi
done

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    add_check "Docker" "Daemon" "PASS"
  else
    add_check "Docker" "Daemon" "FAIL" "" "Verifique systemctl status docker e sua permissão no grupo docker."
  fi

  if docker compose version >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker-compose --version)"
  else
    add_check "Docker" "Compose" "WARN" "" "Instale uma implementação compatível do Docker Compose."
  fi

  if id -nG "$CURRENT_USER" | grep -qw docker; then
    add_check "Docker" "Grupo docker" "PASS"
  else
    add_check "Docker" "Grupo docker" "WARN" "" "sudo usermod -aG docker \$USER && newgrp docker"
  fi
else
  add_check "Docker" "Docker CLI" "SKIP" "Docker não instalado."
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
  add_check "SSH" "Serviço" "PASS"
elif command -v ssh >/dev/null 2>&1; then
  add_check "SSH" "Serviço" "WARN" "Cliente disponível, servidor não ativo." "sudo systemctl enable --now ssh"
else
  add_check "SSH" "Disponibilidade" "SKIP" "SSH não instalado."
fi

if getent hosts registry-1.docker.io >/dev/null 2>&1; then
  add_check "Rede" "DNS Docker Hub" "PASS"
else
  add_check "Rede" "DNS Docker Hub" "FAIL" "" "Verifique DNS, VPN, proxy ou firewall."
fi

TMP_BODY="$(mktemp)"
TMP_ERR="$(mktemp)"
trap 'rm -f "$TMP_BODY" "$TMP_ERR"' EXIT

set +e
HTTP_CODE="$(curl -sS --max-time 10 -o "$TMP_BODY" -w "%{http_code}" https://registry-1.docker.io/v2/ 2>"$TMP_ERR")"
CURL_RC=$?
set -e

if [[ $CURL_RC -eq 0 ]]; then
  add_check "Rede" "TLS/HTTPS" "PASS" "HTTP $HTTP_CODE"
else
  add_check "Rede" "TLS/HTTPS" "FAIL" "$(cat "$TMP_ERR")" "Verifique proxy/certificado corporativo."
fi

if [[ -f "$MANIFEST" ]]; then
  if jq -e '.schema_version == 1 or .schema_version == 2' "$MANIFEST" >/dev/null 2>&1; then
    schema="$(jq -r '.schema_version' "$MANIFEST")"
    add_check "Estado" "Manifesto" "PASS" "schema=$schema | $MANIFEST"
  else
    add_check "Estado" "Manifesto" "WARN" "Schema ausente ou desconhecido."
  fi

  mapfile -t owned_packages < <(
    jq -r '.packages[]
      | select(.manager == "apt" and .installed_by_devkit == true and .present == true)
      | .id' "$MANIFEST" 2>/dev/null
  )

  missing=()

  for pkg in "${owned_packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    add_check "Estado" "Drift de pacotes" "PASS" "Nenhum pacote gerenciado desapareceu."
  else
    add_check "Estado" "Drift de pacotes" "WARN" "$(IFS=,; echo "${missing[*]}")" "Reaplique a stack/perfil ou atualize o manifesto."
  fi
else
  add_check "Estado" "Manifesto" "SKIP" "Ainda não criado; execute uma instalação v0.4+."
fi

if [[ "$TOTAL" -gt 0 ]]; then
  SCORE=$((PASSED * 100 / TOTAL))
else
  SCORE=0
fi

echo
echo "================================================"
echo "Resumo"
echo "================================================"
echo "Score:    $SCORE%"
echo "Checks:   $TOTAL"
echo "OK:       $PASSED"
echo "Avisos:   $WARNINGS"
echo "Falhas:   $FAILED"

if [[ "$FAILED" -eq 0 && "$WARNINGS" -eq 0 ]]; then
  echo
  echo "Ambiente saudável para os checks aplicáveis."
elif [[ "$FAILED" -eq 0 ]]; then
  echo
  echo "Ambiente utilizável, com pontos de atenção."
else
  echo
  echo "Há falhas que merecem correção antes de continuar."
fi

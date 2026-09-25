#!/usr/bin/env bash
set -u

# Dev Doctor v3
#
# Purpose:
#   Diagnose the current development environment without changing it.
#
# Safety:
#   This script is read-only. Suggested remediation commands are printed for
#   the user to review; they are never executed automatically.
#
# Exit behavior:
#   The doctor reports findings but keeps its historical human-oriented behavior.
#   The CLI may wrap this output in the public JSON envelope when --json is used.

VERBOSE=0
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=1
      shift
      ;;
    --json)
      JSON_MODE=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Uso:
  bash diagnostics/dev-doctor.sh [--verbose] [--json]

--verbose  mostra causa provável e comando de verificação para avisos/falhas.
--json     emite um relatório estruturado com os checks do Doctor v3.
EOF
      exit 0
      ;;
    *)
      echo "Opção desconhecida: $1" >&2
      exit 64
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/.super-dev-kit/manifest.json"
CURRENT_USER="${USER:-$(id -un 2>/dev/null || echo root)}"

TOTAL=0
PASSED=0
WARNINGS=0
FAILED=0
CHECKS_FILE="$(mktemp)"
trap 'rm -f "$CHECKS_FILE"' EXIT

if [[ "$JSON_MODE" -eq 1 ]] && ! command -v python3 >/dev/null 2>&1; then
  echo "python3 é necessário para --json." >&2
  exit 69
fi

sanitize_field() {
  local value="$1"
  value="${value//
  local category="$1"
  local name="$2"
  local status="$3"
  local detail="${4:-}"
  local hint="${5:-}"
  local cause="${6:-}"
  local verify="${7:-}"
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

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(sanitize_field "$category")" \
    "$(sanitize_field "$name")" \
    "$(sanitize_field "$status")" \
    "$(sanitize_field "$detail")" \
    "$(sanitize_field "$hint")" \
    "$(sanitize_field "$cause")" \
    "$(sanitize_field "$verify")" >> "$CHECKS_FILE"

  if [[ "$JSON_MODE" -eq 0 ]]; then
    printf '%-9s %-12s %s\n' "$label" "$category" "$name"

    [[ -n "$detail" ]] && printf '          %s\n' "$detail"

    if [[ "$status" == "WARN" || "$status" == "FAIL" ]]; then
      if [[ "$VERBOSE" -eq 1 && -n "$cause" ]]; then
        printf '          Causa provável: %s\n' "$cause"
      fi
      [[ -n "$hint" ]] && printf '          Sugestão: %s\n' "$hint"
      if [[ "$VERBOSE" -eq 1 && -n "$verify" ]]; then
        printf '          Verifique: %s\n' "$verify"
      fi
    fi
  fi
}

SYSTEM_NAME="$(uname -s)"
if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  SYSTEM_NAME="${PRETTY_NAME:-Linux}"
fi

if [[ "$JSON_MODE" -eq 0 ]]; then
  echo "================================================"
  echo "       SUPER DEV KIT - DEV DOCTOR v3"
  echo "================================================"
  echo
  echo "Sistema: $SYSTEM_NAME"
  echo "Kernel:  $(uname -r)"
  echo "Host:    $(hostname)"
  echo
fi

available_kb="$(df -Pk / | awk 'NR==2 {print $4}')"

if [[ "$available_kb" =~ ^[0-9]+$ ]] && (( available_kb > 5242880 )); then
  add_check "Sistema" "Espaço em disco" "PASS" "$(df -h / | awk 'NR==2 {print $4 " livres"}')"
else
  add_check "Sistema" "Espaço em disco" "WARN" "$(df -h / | awk 'NR==2 {print $4 " livres"}')" "Libere espaço antes de instalar SDKs, imagens e dependências." "O filesystem raiz está abaixo do mínimo recomendado de 5 GB livres." "df -h /"
fi

for cmd in git curl jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    add_check "Core" "$cmd" "PASS" "$(command -v "$cmd")"
  else
    add_check "Core" "$cmd" "FAIL" "" "Instale o pacote e confirme o PATH." "O comando não foi localizado no PATH da sessão atual." "command -v $cmd"
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
    add_check "Docker" "Daemon" "FAIL" "" "Verifique o serviço Docker e sua permissão no grupo docker." "A CLI existe, mas não conseguiu conversar com o daemon; serviço parado ou permissão insuficiente são causas comuns." "docker info && systemctl status docker"
  fi

  if docker compose version >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker-compose --version)"
  else
    add_check "Docker" "Compose" "WARN" "" "Instale uma implementação compatível do Docker Compose." "Docker está disponível, mas nenhum Compose compatível foi localizado." "docker compose version"
  fi

  if id -nG "$CURRENT_USER" | grep -qw docker; then
    add_check "Docker" "Grupo docker" "PASS"
  else
    add_check "Docker" "Grupo docker" "WARN" "" "sudo usermod -aG docker \$USER && newgrp docker" "O usuário atual não pertence ao grupo docker; comandos sem sudo podem falhar." "id -nG \$USER"
  fi
else
  add_check "Docker" "Docker CLI" "SKIP" "Docker não instalado."
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
  add_check "SSH" "Serviço" "PASS"
elif command -v ssh >/dev/null 2>&1; then
  add_check "SSH" "Serviço" "WARN" "Cliente disponível, servidor não ativo." "Ative o servidor apenas se esta máquina precisar receber conexões SSH." "O cliente SSH existe, mas o serviço sshd não está ativo." "systemctl status ssh"
else
  add_check "SSH" "Disponibilidade" "SKIP" "SSH não instalado."
fi

if getent hosts registry-1.docker.io >/dev/null 2>&1; then
  add_check "Rede" "DNS Docker Hub" "PASS"
else
  add_check "Rede" "DNS Docker Hub" "FAIL" "" "Verifique DNS, VPN, proxy ou firewall." "O hostname do Docker Registry não pôde ser resolvido." "getent hosts registry-1.docker.io"
fi

TMP_BODY="$(mktemp)"
TMP_ERR="$(mktemp)"
trap 'rm -f "$CHECKS_FILE" "$TMP_BODY" "$TMP_ERR"' EXIT

set +e
HTTP_CODE="$(curl -sS --max-time 10 -o "$TMP_BODY" -w "%{http_code}" https://registry-1.docker.io/v2/ 2>"$TMP_ERR")"
CURL_RC=$?
set -e

if [[ $CURL_RC -eq 0 ]]; then
  add_check "Rede" "TLS/HTTPS" "PASS" "HTTP $HTTP_CODE"
else
  add_check "Rede" "TLS/HTTPS" "FAIL" "$(cat "$TMP_ERR")" "Verifique proxy/certificado corporativo; não desative TLS permanentemente." "A conexão HTTPS falhou antes de obter uma resposta válida; inspeção TLS ou cadeia de CA são causas possíveis." "curl -v https://registry-1.docker.io/v2/"
fi

if [[ -f "$MANIFEST" ]]; then
  if jq -e '.schema_version == 1 or .schema_version == 2' "$MANIFEST" >/dev/null 2>&1; then
    schema="$(jq -r '.schema_version' "$MANIFEST")"
    add_check "Estado" "Manifesto" "PASS" "schema=$schema | $MANIFEST"
  else
    add_check "Estado" "Manifesto" "WARN" "Schema ausente ou desconhecido." "Revise o manifesto antes de cleanup/import." "O arquivo existe, mas o schema não é reconhecido pela linha v1." "jq '.schema_version' .super-dev-kit/manifest.json"
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
    add_check "Estado" "Drift de pacotes" "WARN" "$(IFS=,; echo "${missing[*]}")" "Reaplique a stack/perfil ou atualize o manifesto após confirmar a intenção." "O manifesto marca pacotes gerenciados como presentes, mas o sistema não os encontra." "devkit compare"
  fi
else
  add_check "Estado" "Manifesto" "SKIP" "Ainda não criado; execute uma instalação v0.4+."
fi

if [[ "$TOTAL" -gt 0 ]]; then
  SCORE=$((PASSED * 100 / TOTAL))
else
  SCORE=0
fi

if [[ "$FAILED" -gt 0 ]]; then
  HEALTH="failed"
elif [[ "$WARNINGS" -gt 0 ]]; then
  HEALTH="warning"
else
  HEALTH="healthy"
fi

if [[ "$JSON_MODE" -eq 1 ]]; then
  python3 - "$CHECKS_FILE" "$SCORE" "$TOTAL" "$PASSED" "$WARNINGS" "$FAILED" "$HEALTH" "$SYSTEM_NAME" "$(uname -r)" "$(hostname)" <<'PY'
import json
import sys
from datetime import datetime, timezone

path, score, total, passed, warnings, failed, health, system, kernel, host = sys.argv[1:]
checks = []

with open(path, encoding="utf-8") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        parts += [""] * (7 - len(parts))
        category, name, status, detail, hint, cause, verify = parts[:7]
        item = {
            "category": category,
            "name": name,
            "status": status,
        }
        if detail:
            item["detail"] = detail
        if hint:
            item["hint"] = hint
        if cause:
            item["cause"] = cause
        if verify:
            item["verify"] = verify
        checks.append(item)

payload = {
    "schema_version": 1,
    "command": "doctor",
    "success": True,
    "exit_code": 0,
    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "data": {
        "doctor_version": 3,
        "platform": "linux",
        "system": system,
        "kernel": kernel,
        "host": host,
        "health": health,
        "score": int(score),
        "summary": {
            "checks": int(total),
            "passed": int(passed),
            "warnings": int(warnings),
            "failed": int(failed),
        },
        "checks": checks,
    },
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
else
  echo
  echo "================================================"
  echo "Resumo"
  echo "================================================"
  echo "Saúde:    $HEALTH"
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
fi
\t'/ }"
  value="${value//
  local category="$1"
  local name="$2"
  local status="$3"
  local detail="${4:-}"
  local hint="${5:-}"
  local cause="${6:-}"
  local verify="${7:-}"
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

  if [[ "$status" == "WARN" || "$status" == "FAIL" ]]; then
    if [[ "$VERBOSE" -eq 1 && -n "$cause" ]]; then
      printf '          Causa provável: %s\n' "$cause"
    fi
    [[ -n "$hint" ]] && printf '          Sugestão: %s\n' "$hint"
    if [[ "$VERBOSE" -eq 1 && -n "$verify" ]]; then
      printf '          Verifique: %s\n' "$verify"
    fi
  fi
}

echo "================================================"
echo "       SUPER DEV KIT - DEV DOCTOR v3"
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
  add_check "Sistema" "Espaço em disco" "WARN" "$(df -h / | awk 'NR==2 {print $4 " livres"}')" "Libere espaço antes de instalar SDKs, imagens e dependências." "O filesystem raiz está abaixo do mínimo recomendado de 5 GB livres." "df -h /"
fi

for cmd in git curl jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    add_check "Core" "$cmd" "PASS" "$(command -v "$cmd")"
  else
    add_check "Core" "$cmd" "FAIL" "" "Instale o pacote e confirme o PATH." "O comando não foi localizado no PATH da sessão atual." "command -v $cmd"
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
    add_check "Docker" "Daemon" "FAIL" "" "Verifique o serviço Docker e sua permissão no grupo docker." "A CLI existe, mas não conseguiu conversar com o daemon; serviço parado ou permissão insuficiente são causas comuns." "docker info && systemctl status docker"
  fi

  if docker compose version >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker-compose --version)"
  else
    add_check "Docker" "Compose" "WARN" "" "Instale uma implementação compatível do Docker Compose." "Docker está disponível, mas nenhum Compose compatível foi localizado." "docker compose version"
  fi

  if id -nG "$CURRENT_USER" | grep -qw docker; then
    add_check "Docker" "Grupo docker" "PASS"
  else
    add_check "Docker" "Grupo docker" "WARN" "" "sudo usermod -aG docker \$USER && newgrp docker" "O usuário atual não pertence ao grupo docker; comandos sem sudo podem falhar." "id -nG \$USER"
  fi
else
  add_check "Docker" "Docker CLI" "SKIP" "Docker não instalado."
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
  add_check "SSH" "Serviço" "PASS"
elif command -v ssh >/dev/null 2>&1; then
  add_check "SSH" "Serviço" "WARN" "Cliente disponível, servidor não ativo." "Ative o servidor apenas se esta máquina precisar receber conexões SSH." "O cliente SSH existe, mas o serviço sshd não está ativo." "systemctl status ssh"
else
  add_check "SSH" "Disponibilidade" "SKIP" "SSH não instalado."
fi

if getent hosts registry-1.docker.io >/dev/null 2>&1; then
  add_check "Rede" "DNS Docker Hub" "PASS"
else
  add_check "Rede" "DNS Docker Hub" "FAIL" "" "Verifique DNS, VPN, proxy ou firewall." "O hostname do Docker Registry não pôde ser resolvido." "getent hosts registry-1.docker.io"
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
  add_check "Rede" "TLS/HTTPS" "FAIL" "$(cat "$TMP_ERR")" "Verifique proxy/certificado corporativo; não desative TLS permanentemente." "A conexão HTTPS falhou antes de obter uma resposta válida; inspeção TLS ou cadeia de CA são causas possíveis." "curl -v https://registry-1.docker.io/v2/"
fi

if [[ -f "$MANIFEST" ]]; then
  if jq -e '.schema_version == 1 or .schema_version == 2' "$MANIFEST" >/dev/null 2>&1; then
    schema="$(jq -r '.schema_version' "$MANIFEST")"
    add_check "Estado" "Manifesto" "PASS" "schema=$schema | $MANIFEST"
  else
    add_check "Estado" "Manifesto" "WARN" "Schema ausente ou desconhecido." "Revise o manifesto antes de cleanup/import." "O arquivo existe, mas o schema não é reconhecido pela linha v1." "jq '.schema_version' .super-dev-kit/manifest.json"
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
    add_check "Estado" "Drift de pacotes" "WARN" "$(IFS=,; echo "${missing[*]}")" "Reaplique a stack/perfil ou atualize o manifesto após confirmar a intenção." "O manifesto marca pacotes gerenciados como presentes, mas o sistema não os encontra." "devkit compare"
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
\n'/ }"
  value="${value//
  local category="$1"
  local name="$2"
  local status="$3"
  local detail="${4:-}"
  local hint="${5:-}"
  local cause="${6:-}"
  local verify="${7:-}"
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

  if [[ "$status" == "WARN" || "$status" == "FAIL" ]]; then
    if [[ "$VERBOSE" -eq 1 && -n "$cause" ]]; then
      printf '          Causa provável: %s\n' "$cause"
    fi
    [[ -n "$hint" ]] && printf '          Sugestão: %s\n' "$hint"
    if [[ "$VERBOSE" -eq 1 && -n "$verify" ]]; then
      printf '          Verifique: %s\n' "$verify"
    fi
  fi
}

echo "================================================"
echo "       SUPER DEV KIT - DEV DOCTOR v3"
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
  add_check "Sistema" "Espaço em disco" "WARN" "$(df -h / | awk 'NR==2 {print $4 " livres"}')" "Libere espaço antes de instalar SDKs, imagens e dependências." "O filesystem raiz está abaixo do mínimo recomendado de 5 GB livres." "df -h /"
fi

for cmd in git curl jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    add_check "Core" "$cmd" "PASS" "$(command -v "$cmd")"
  else
    add_check "Core" "$cmd" "FAIL" "" "Instale o pacote e confirme o PATH." "O comando não foi localizado no PATH da sessão atual." "command -v $cmd"
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
    add_check "Docker" "Daemon" "FAIL" "" "Verifique o serviço Docker e sua permissão no grupo docker." "A CLI existe, mas não conseguiu conversar com o daemon; serviço parado ou permissão insuficiente são causas comuns." "docker info && systemctl status docker"
  fi

  if docker compose version >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker-compose --version)"
  else
    add_check "Docker" "Compose" "WARN" "" "Instale uma implementação compatível do Docker Compose." "Docker está disponível, mas nenhum Compose compatível foi localizado." "docker compose version"
  fi

  if id -nG "$CURRENT_USER" | grep -qw docker; then
    add_check "Docker" "Grupo docker" "PASS"
  else
    add_check "Docker" "Grupo docker" "WARN" "" "sudo usermod -aG docker \$USER && newgrp docker" "O usuário atual não pertence ao grupo docker; comandos sem sudo podem falhar." "id -nG \$USER"
  fi
else
  add_check "Docker" "Docker CLI" "SKIP" "Docker não instalado."
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
  add_check "SSH" "Serviço" "PASS"
elif command -v ssh >/dev/null 2>&1; then
  add_check "SSH" "Serviço" "WARN" "Cliente disponível, servidor não ativo." "Ative o servidor apenas se esta máquina precisar receber conexões SSH." "O cliente SSH existe, mas o serviço sshd não está ativo." "systemctl status ssh"
else
  add_check "SSH" "Disponibilidade" "SKIP" "SSH não instalado."
fi

if getent hosts registry-1.docker.io >/dev/null 2>&1; then
  add_check "Rede" "DNS Docker Hub" "PASS"
else
  add_check "Rede" "DNS Docker Hub" "FAIL" "" "Verifique DNS, VPN, proxy ou firewall." "O hostname do Docker Registry não pôde ser resolvido." "getent hosts registry-1.docker.io"
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
  add_check "Rede" "TLS/HTTPS" "FAIL" "$(cat "$TMP_ERR")" "Verifique proxy/certificado corporativo; não desative TLS permanentemente." "A conexão HTTPS falhou antes de obter uma resposta válida; inspeção TLS ou cadeia de CA são causas possíveis." "curl -v https://registry-1.docker.io/v2/"
fi

if [[ -f "$MANIFEST" ]]; then
  if jq -e '.schema_version == 1 or .schema_version == 2' "$MANIFEST" >/dev/null 2>&1; then
    schema="$(jq -r '.schema_version' "$MANIFEST")"
    add_check "Estado" "Manifesto" "PASS" "schema=$schema | $MANIFEST"
  else
    add_check "Estado" "Manifesto" "WARN" "Schema ausente ou desconhecido." "Revise o manifesto antes de cleanup/import." "O arquivo existe, mas o schema não é reconhecido pela linha v1." "jq '.schema_version' .super-dev-kit/manifest.json"
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
    add_check "Estado" "Drift de pacotes" "WARN" "$(IFS=,; echo "${missing[*]}")" "Reaplique a stack/perfil ou atualize o manifesto após confirmar a intenção." "O manifesto marca pacotes gerenciados como presentes, mas o sistema não os encontra." "devkit compare"
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
\r'/ }"
  printf '%s' "$value"
}

add_check() {
  local category="$1"
  local name="$2"
  local status="$3"
  local detail="${4:-}"
  local hint="${5:-}"
  local cause="${6:-}"
  local verify="${7:-}"
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

  if [[ "$status" == "WARN" || "$status" == "FAIL" ]]; then
    if [[ "$VERBOSE" -eq 1 && -n "$cause" ]]; then
      printf '          Causa provável: %s\n' "$cause"
    fi
    [[ -n "$hint" ]] && printf '          Sugestão: %s\n' "$hint"
    if [[ "$VERBOSE" -eq 1 && -n "$verify" ]]; then
      printf '          Verifique: %s\n' "$verify"
    fi
  fi
}

echo "================================================"
echo "       SUPER DEV KIT - DEV DOCTOR v3"
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
  add_check "Sistema" "Espaço em disco" "WARN" "$(df -h / | awk 'NR==2 {print $4 " livres"}')" "Libere espaço antes de instalar SDKs, imagens e dependências." "O filesystem raiz está abaixo do mínimo recomendado de 5 GB livres." "df -h /"
fi

for cmd in git curl jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    add_check "Core" "$cmd" "PASS" "$(command -v "$cmd")"
  else
    add_check "Core" "$cmd" "FAIL" "" "Instale o pacote e confirme o PATH." "O comando não foi localizado no PATH da sessão atual." "command -v $cmd"
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
    add_check "Docker" "Daemon" "FAIL" "" "Verifique o serviço Docker e sua permissão no grupo docker." "A CLI existe, mas não conseguiu conversar com o daemon; serviço parado ou permissão insuficiente são causas comuns." "docker info && systemctl status docker"
  fi

  if docker compose version >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    add_check "Docker" "Compose" "PASS" "$(docker-compose --version)"
  else
    add_check "Docker" "Compose" "WARN" "" "Instale uma implementação compatível do Docker Compose." "Docker está disponível, mas nenhum Compose compatível foi localizado." "docker compose version"
  fi

  if id -nG "$CURRENT_USER" | grep -qw docker; then
    add_check "Docker" "Grupo docker" "PASS"
  else
    add_check "Docker" "Grupo docker" "WARN" "" "sudo usermod -aG docker \$USER && newgrp docker" "O usuário atual não pertence ao grupo docker; comandos sem sudo podem falhar." "id -nG \$USER"
  fi
else
  add_check "Docker" "Docker CLI" "SKIP" "Docker não instalado."
fi

if systemctl is-active --quiet ssh 2>/dev/null; then
  add_check "SSH" "Serviço" "PASS"
elif command -v ssh >/dev/null 2>&1; then
  add_check "SSH" "Serviço" "WARN" "Cliente disponível, servidor não ativo." "Ative o servidor apenas se esta máquina precisar receber conexões SSH." "O cliente SSH existe, mas o serviço sshd não está ativo." "systemctl status ssh"
else
  add_check "SSH" "Disponibilidade" "SKIP" "SSH não instalado."
fi

if getent hosts registry-1.docker.io >/dev/null 2>&1; then
  add_check "Rede" "DNS Docker Hub" "PASS"
else
  add_check "Rede" "DNS Docker Hub" "FAIL" "" "Verifique DNS, VPN, proxy ou firewall." "O hostname do Docker Registry não pôde ser resolvido." "getent hosts registry-1.docker.io"
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
  add_check "Rede" "TLS/HTTPS" "FAIL" "$(cat "$TMP_ERR")" "Verifique proxy/certificado corporativo; não desative TLS permanentemente." "A conexão HTTPS falhou antes de obter uma resposta válida; inspeção TLS ou cadeia de CA são causas possíveis." "curl -v https://registry-1.docker.io/v2/"
fi

if [[ -f "$MANIFEST" ]]; then
  if jq -e '.schema_version == 1 or .schema_version == 2' "$MANIFEST" >/dev/null 2>&1; then
    schema="$(jq -r '.schema_version' "$MANIFEST")"
    add_check "Estado" "Manifesto" "PASS" "schema=$schema | $MANIFEST"
  else
    add_check "Estado" "Manifesto" "WARN" "Schema ausente ou desconhecido." "Revise o manifesto antes de cleanup/import." "O arquivo existe, mas o schema não é reconhecido pela linha v1." "jq '.schema_version' .super-dev-kit/manifest.json"
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
    add_check "Estado" "Drift de pacotes" "WARN" "$(IFS=,; echo "${missing[*]}")" "Reaplique a stack/perfil ou atualize o manifesto após confirmar a intenção." "O manifesto marca pacotes gerenciados como presentes, mas o sistema não os encontra." "devkit compare"
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

#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$ROOT_DIR/reports"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$REPORT_DIR/linux-inventory-$STAMP.txt"

mkdir -p "$REPORT_DIR"

{
  echo "SUPER DEV KIT - INVENTORY"
  echo "Gerado em: $(date -Iseconds)"
  echo
  echo "=== SISTEMA ==="
  uname -a
  [[ -r /etc/os-release ]] && cat /etc/os-release
  echo
  echo "=== RECURSOS ==="
  df -h /
  free -h 2>/dev/null || true
  echo
  echo "=== FERRAMENTAS ==="
  for cmd in git node npm python3 docker curl wget ssh code jq; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "[$cmd]"
      case "$cmd" in
        git) git --version ;;
        node) node --version ;;
        npm) npm --version ;;
        python3) python3 --version ;;
        docker) docker --version ;;
        curl) curl --version | head -n 1 ;;
        wget) wget --version | head -n 1 ;;
        ssh) ssh -V 2>&1 ;;
        code) code --version | head -n 1 ;;
        jq) jq --version ;;
      esac
    else
      echo "[$cmd] não encontrado"
    fi
  done
  echo
  echo "=== DOCKER COMPOSE ==="
  docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || true
  echo
  echo "=== VS CODE EXTENSIONS ==="
  code --list-extensions 2>/dev/null || true
  echo
  echo "=== PACOTES RELEVANTES ==="
  dpkg-query -W -f='${Package}	${Version}
' 2>/dev/null |
    grep -E '^(docker|nodejs|npm|python3|git|postgresql-client|default-mysql-client|sqlite3)' || true
} > "$OUT"

echo "[OK] Inventário salvo em:"
echo "     $OUT"

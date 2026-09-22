#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE=""
APPLY=0
INCLUDE_DOCKER=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/cleanup.sh --profile frontend
  sudo bash tools/cleanup.sh --profile datasql --apply
  sudo bash tools/cleanup.sh --profile devops --include-docker --apply

Por segurança, sem --apply o script apenas mostra o que faria.

Opções:
  --profile PERFIL     frontend | backend | fullstack | datasql | devops
  --include-docker     inclui remoção do Docker/Compose
  --apply              executa de fato as remoções
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --include-docker)
      INCLUDE_DOCKER=1
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

PROFILE="${PROFILE,,}"

case "$PROFILE" in
  frontend|backend|fullstack|datasql|devops) ;;
  *)
    echo "Informe um perfil válido." >&2
    usage
    exit 1
    ;;
esac

packages=()

case "$PROFILE" in
  frontend)
    packages+=(nodejs npm)
    ;;
  backend|fullstack)
    packages+=(nodejs npm python3-pip python3-venv sqlite3)
    ;;
  datasql)
    packages+=(python3-pip python3-venv sqlite3 postgresql-client default-mysql-client)
    ;;
  devops)
    ;;
esac

if [[ "$INCLUDE_DOCKER" -eq 1 ]]; then
  packages+=(docker.io docker-compose-v2 docker-compose-plugin docker-compose)
fi

echo "Perfil: $PROFILE"
echo
echo "Pacotes candidatos à remoção:"
if [[ ${#packages[@]} -eq 0 ]]; then
  echo "  (nenhum; use --include-docker se desejar incluir Docker)"
else
  printf '  - %s\n' "${packages[@]}"
fi

echo
echo "IMPORTANTE:"
echo "Este script não sabe se um pacote já existia antes do Super Dev Kit."
echo "Revise a lista antes de usar --apply."
echo "Volumes e imagens Docker NÃO são apagados automaticamente."

if [[ "$APPLY" -ne 1 ]]; then
  echo
  echo "[DRY-RUN] Nenhuma alteração foi feita."
  echo "Para aplicar:"
  echo "  sudo bash tools/cleanup.sh --profile $PROFILE --apply"
  exit 0
fi

if [[ "$EUID" -ne 0 ]]; then
  echo "Use sudo ao executar com --apply."
  exit 1
fi

read -r -p "Digite REMOVER para confirmar: " confirm

if [[ "$confirm" != "REMOVER" ]]; then
  echo "Operação cancelada."
  exit 0
fi

installed=()

for pkg in "${packages[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    installed+=("$pkg")
  fi
done

if [[ ${#installed[@]} -eq 0 ]]; then
  echo "Nenhum dos pacotes selecionados está instalado."
  exit 0
fi

apt-get remove -y "${installed[@]}"
apt-get autoremove -y

echo "[OK] Cleanup concluído."

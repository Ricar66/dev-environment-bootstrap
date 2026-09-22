#!/usr/bin/env bash
set -Eeuo pipefail

YES=0
CA_FILE=""

usage() {
  cat <<'EOF'
Uso:
  sudo bash certificates/import-ca-linux.sh /caminho/certificado.cer
  sudo bash certificates/import-ca-linux.sh --auto
  sudo bash certificates/import-ca-linux.sh --auto --yes

Opções:
  --auto   Procura .cer/.crt em Downloads, /media e /mnt.
  --yes    Não pede confirmação antes de confiar no certificado.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto)
      CA_FILE="AUTO"
      shift
      ;;
    --yes)
      YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$CA_FILE" ]]; then
        CA_FILE="$1"
        shift
      else
        echo "Argumento desconhecido: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ "$EUID" -ne 0 ]]; then
  echo "Execute com sudo:"
  echo "  sudo bash $0 ..."
  exit 1
fi

ORIGINAL_USER="${SUDO_USER:-root}"
USER_HOME="$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)"
USER_HOME="${USER_HOME:-/root}"

find_candidates() {
  local roots=(
    "$USER_HOME/Downloads"
    "/media"
    "/mnt"
  )

  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    find "$root" -maxdepth 3 -type f \( -iname "*.cer" -o -iname "*.crt" \) 2>/dev/null || true
  done
}

if [[ -z "$CA_FILE" ]]; then
  usage
  exit 1
fi

if [[ "$CA_FILE" == "AUTO" ]]; then
  mapfile -t candidates < <(find_candidates | sort -u)

  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "Nenhum certificado .cer/.crt encontrado automaticamente."
    exit 1
  fi

  echo "Certificados encontrados:"
  for i in "${!candidates[@]}"; do
    echo "[$i] ${candidates[$i]}"
  done

  if [[ ${#candidates[@]} -eq 1 ]]; then
    CA_FILE="${candidates[0]}"
  else
    read -r -p "Escolha o número do certificado: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || { echo "Seleção inválida."; exit 1; }
    (( choice < ${#candidates[@]} )) || { echo "Seleção inválida."; exit 1; }
    CA_FILE="${candidates[$choice]}"
  fi
fi

[[ -f "$CA_FILE" ]] || { echo "Certificado não encontrado: $CA_FILE"; exit 1; }

echo
echo "Arquivo selecionado:"
echo "  $CA_FILE"
echo

TMP_PEM="$(mktemp)"
trap 'rm -f "$TMP_PEM"' EXIT

if openssl x509 -in "$CA_FILE" -noout >/dev/null 2>&1; then
  cp "$CA_FILE" "$TMP_PEM"
elif openssl x509 -inform DER -in "$CA_FILE" -noout >/dev/null 2>&1; then
  openssl x509 -inform DER -in "$CA_FILE" -out "$TMP_PEM"
else
  echo "O arquivo não parece ser um certificado X.509 válido."
  exit 1
fi

echo "Detalhes do certificado:"
openssl x509 -in "$TMP_PEM" -noout -subject -issuer -fingerprint -sha256 -dates
echo

if [[ "$YES" -ne 1 ]]; then
  read -r -p "Confiar neste certificado no sistema? [s/N]: " answer
  case "${answer,,}" in
    s|sim|y|yes) ;;
    *) echo "Operação cancelada."; exit 0 ;;
  esac
fi

DEST="/usr/local/share/ca-certificates/super-dev-kit-local-ca.crt"

install -m 0644 "$TMP_PEM" "$DEST"
update-ca-certificates

if systemctl is-active --quiet docker 2>/dev/null; then
  systemctl restart docker
fi

echo
echo "[OK] Certificado instalado em:"
echo "     $DEST"
echo

echo "Teste HTTPS do Docker Hub:"
if curl -sS --max-time 15 https://registry-1.docker.io/v2/; then
  echo
  echo "[OK] TLS/HTTPS respondeu."
else
  echo
  echo "[AVISO] O teste HTTPS ainda falhou."
  echo "Execute:"
  echo '  curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -Ei "issuer:|subject:"'
fi

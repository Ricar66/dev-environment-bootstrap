#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh"
DOCTOR="$ROOT_DIR/diagnostics/dev-doctor.sh"

show_menu() {
  clear || true
  cat <<'MENU'
=========================================
             SUPER DEV KIT
=========================================

1. Preparar Ubuntu / VM
2. Preparar Ubuntu com certificado CA
3. Diagnosticar ambiente
0. Sair

MENU
}

while true; do
  show_menu
  read -r -p "Escolha uma opção: " choice

  case "$choice" in
    1)
      sudo bash "$INSTALLER"
      ;;
    2)
      read -r -p "Caminho do certificado .cer/.crt: " ca_file
      sudo bash "$INSTALLER" "$ca_file"
      ;;
    3)
      bash "$DOCTOR"
      read -r -p "Pressione Enter para voltar..." _
      ;;
    0)
      exit 0
      ;;
    *)
      echo "Opção inválida."
      sleep 1
      ;;
  esac
done

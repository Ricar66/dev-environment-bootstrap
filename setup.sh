#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh"
DOCTOR="$ROOT_DIR/diagnostics/dev-doctor.sh"
CA_IMPORTER="$ROOT_DIR/certificates/import-ca-linux.sh"

show_menu() {
  clear || true
  cat <<'MENU'
==============================================
               SUPER DEV KIT
==============================================

1.  Essential
2.  Frontend
3.  Backend
4.  Full Stack
5.  Data / SQL
6.  DevOps / Docker
7.  Importar certificado CA (opcional)
8.  Dev Doctor
9.  Mostrar exemplos Docker
0.  Sair

MENU
}

run_profile() {
  local profile="$1"
  sudo bash "$INSTALLER" --profile "$profile"
}

while true; do
  show_menu
  read -r -p "Escolha uma opção: " choice

  case "$choice" in
    1) run_profile essential ;;
    2) run_profile frontend ;;
    3) run_profile backend ;;
    4) run_profile fullstack ;;
    5) run_profile datasql ;;
    6) run_profile devops ;;
    7)
      sudo bash "$CA_IMPORTER" --auto
      read -r -p "Pressione Enter para voltar..." _
      ;;
    8)
      bash "$DOCTOR"
      read -r -p "Pressione Enter para voltar..." _
      ;;
    9)
      cat "$ROOT_DIR/examples/README.md"
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

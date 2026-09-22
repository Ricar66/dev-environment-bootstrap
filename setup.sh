#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh"
DOCTOR="$ROOT_DIR/diagnostics/dev-doctor.sh"
CA_IMPORTER="$ROOT_DIR/certificates/import-ca-linux.sh"
EXTENSIONS="$ROOT_DIR/tools/install-vscode-extensions.sh"
CONFIG_RUNNER="$ROOT_DIR/tools/run-config.sh"
UPDATER="$ROOT_DIR/tools/update-devkit.sh"
INVENTORY="$ROOT_DIR/tools/inventory.sh"
CLEANUP="$ROOT_DIR/tools/cleanup.sh"
CONFIG_EXAMPLE="$ROOT_DIR/config/devkit.config.example.json"
CONFIG_LOCAL="$ROOT_DIR/config/devkit.config.json"

read_profile() {
  echo >&2
  echo "1. Essential" >&2
  echo "2. Frontend" >&2
  echo "3. Backend" >&2
  echo "4. Full Stack" >&2
  echo "5. Data / SQL" >&2
  echo "6. DevOps" >&2
  echo >&2

  read -r -p "Escolha o perfil: " profile_choice

  case "$profile_choice" in
    1) echo "essential" ;;
    2) echo "frontend" ;;
    3) echo "backend" ;;
    4) echo "fullstack" ;;
    5) echo "datasql" ;;
    6) echo "devops" ;;
    *) return 1 ;;
  esac
}

show_menu() {
  clear || true
  cat <<'MENU'
================================================
                 SUPER DEV KIT
================================================

1.  Instalar por perfil
2.  Dry-run de um perfil
3.  Extensões VS Code por perfil
4.  Executar configuração JSON
5.  Dry-run da configuração JSON
6.  Dev Doctor
7.  Exportar inventário do ambiente
8.  Atualizar Super Dev Kit
9.  Preview de cleanup/uninstall
10. Importar certificado CA (opcional)
11. Criar configuração local a partir do exemplo
12. Mostrar exemplos Docker
0.  Sair

MENU
}

while true; do
  show_menu
  read -r -p "Escolha uma opção: " choice

  case "$choice" in
    1)
      if profile="$(read_profile)"; then
        sudo bash "$INSTALLER" --profile "$profile"
      else
        echo "Perfil inválido."
        sleep 1
      fi
      ;;
    2)
      if profile="$(read_profile)"; then
        bash "$INSTALLER" --profile "$profile" --dry-run
      else
        echo "Perfil inválido."
      fi
      read -r -p "Pressione Enter para voltar..." _
      ;;
    3)
      if profile="$(read_profile)"; then
        bash "$EXTENSIONS" --profile "$profile"
      else
        echo "Perfil inválido."
      fi
      read -r -p "Pressione Enter para voltar..." _
      ;;
    4)
      if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo "Configuração local não encontrada."
        echo "Use a opção 11 primeiro."
      else
        bash "$CONFIG_RUNNER" --config "$CONFIG_LOCAL"
      fi
      read -r -p "Pressione Enter para voltar..." _
      ;;
    5)
      if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo "Configuração local não encontrada."
      else
        bash "$CONFIG_RUNNER" --config "$CONFIG_LOCAL" --dry-run
      fi
      read -r -p "Pressione Enter para voltar..." _
      ;;
    6)
      bash "$DOCTOR"
      read -r -p "Pressione Enter para voltar..." _
      ;;
    7)
      bash "$INVENTORY"
      read -r -p "Pressione Enter para voltar..." _
      ;;
    8)
      bash "$UPDATER"
      read -r -p "Pressione Enter para voltar..." _
      ;;
    9)
      if profile="$(read_profile)"; then
        if [[ "$profile" == "essential" ]]; then
          echo "Cleanup não é executado para o perfil Essential."
        else
          bash "$CLEANUP" --profile "$profile"
        fi
      else
        echo "Perfil inválido."
      fi
      read -r -p "Pressione Enter para voltar..." _
      ;;
    10)
      sudo bash "$CA_IMPORTER" --auto
      read -r -p "Pressione Enter para voltar..." _
      ;;
    11)
      if [[ -f "$CONFIG_LOCAL" ]]; then
        echo "config/devkit.config.json já existe."
      else
        cp "$CONFIG_EXAMPLE" "$CONFIG_LOCAL"
        echo "[OK] Configuração criada:"
        echo "     $CONFIG_LOCAL"
      fi
      read -r -p "Pressione Enter para voltar..." _
      ;;
    12)
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

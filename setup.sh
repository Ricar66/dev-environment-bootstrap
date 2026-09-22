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
SHOW_STATE="$ROOT_DIR/tools/show-state.sh"
BACKUP_VSCODE="$ROOT_DIR/tools/backup-vscode.sh"
RESTORE_VSCODE="$ROOT_DIR/tools/restore-vscode.sh"
BACKUP_GIT="$ROOT_DIR/tools/backup-git.sh"
RESTORE_GIT="$ROOT_DIR/tools/restore-git.sh"
CONFIG_EXAMPLE="$ROOT_DIR/config/devkit.config.example.json"
CONFIG_LOCAL="$ROOT_DIR/config/devkit.config.json"
VERSION_FILE="$ROOT_DIR/VERSION"
VERSION="dev"
[[ -f "$VERSION_FILE" ]] && VERSION="$(tr -d '\r\n' < "$VERSION_FILE")"

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

pause_menu() {
  read -r -p "Pressione Enter para voltar..." _
}

show_menu() {
  clear || true
  cat <<MENU
====================================================
                 SUPER DEV KIT v$VERSION
====================================================

1.  Instalar por perfil
2.  Dry-run de um perfil
3.  Extensões VS Code por perfil
4.  Executar configuração JSON
5.  Dry-run da configuração JSON
6.  Dev Doctor
7.  Ver manifesto/estado local
8.  Exportar inventário do ambiente
9.  Atualizar Super Dev Kit
10. Preview de cleanup baseado no manifesto
11. Backup do VS Code
12. Preview de restore do VS Code
13. Backup da configuração Git
14. Preview de restore da configuração Git
15. Importar certificado CA (opcional)
16. Criar configuração local a partir do exemplo
17. Mostrar exemplos Docker
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
      fi
      pause_menu
      ;;
    2)
      if profile="$(read_profile)"; then
        bash "$INSTALLER" --profile "$profile" --dry-run
      else
        echo "Perfil inválido."
      fi
      pause_menu
      ;;
    3)
      if profile="$(read_profile)"; then
        bash "$EXTENSIONS" --profile "$profile"
      else
        echo "Perfil inválido."
      fi
      pause_menu
      ;;
    4)
      if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo "Configuração local não encontrada."
        echo "Use a opção 16 primeiro."
      else
        bash "$CONFIG_RUNNER" --config "$CONFIG_LOCAL"
      fi
      pause_menu
      ;;
    5)
      if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo "Configuração local não encontrada."
      else
        bash "$CONFIG_RUNNER" --config "$CONFIG_LOCAL" --dry-run
      fi
      pause_menu
      ;;
    6)
      bash "$DOCTOR"
      pause_menu
      ;;
    7)
      bash "$SHOW_STATE"
      pause_menu
      ;;
    8)
      bash "$INVENTORY"
      pause_menu
      ;;
    9)
      bash "$UPDATER"
      pause_menu
      ;;
    10)
      bash "$CLEANUP"
      pause_menu
      ;;
    11)
      bash "$BACKUP_VSCODE"
      pause_menu
      ;;
    12)
      bash "$RESTORE_VSCODE"
      pause_menu
      ;;
    13)
      bash "$BACKUP_GIT"
      pause_menu
      ;;
    14)
      bash "$RESTORE_GIT"
      pause_menu
      ;;
    15)
      sudo bash "$CA_IMPORTER" --auto
      pause_menu
      ;;
    16)
      if [[ -f "$CONFIG_LOCAL" ]]; then
        echo "config/devkit.config.json já existe."
      else
        cp "$CONFIG_EXAMPLE" "$CONFIG_LOCAL"
        echo "[OK] Configuração criada:"
        echo "     $CONFIG_LOCAL"
      fi
      pause_menu
      ;;
    17)
      cat "$ROOT_DIR/examples/README.md"
      pause_menu
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

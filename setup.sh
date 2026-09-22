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
STACK_WIZARD="$ROOT_DIR/tools/stack-wizard.sh"
EXPORT_ENVIRONMENT="$ROOT_DIR/tools/export-environment.sh"
IMPORT_ENVIRONMENT="$ROOT_DIR/tools/import-environment.sh"
COMPARE_ENVIRONMENT="$ROOT_DIR/tools/compare-environment.sh"
RUNTIME_CHECKER="$ROOT_DIR/tools/check-runtime-versions.sh"
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

show_reproducibility_menu() {
  while true; do
    clear || true
    cat <<MENU
====================================================
        AMBIENTES REPRODUZÍVEIS - v0.6
====================================================

1. Exportar ambiente para lock file
2. Dry-run de importação
3. Importar ambiente do lock
4. Comparar lock x máquina
5. Validar runtimes do config local
6. Validar preset portable
7. Validar preset modern
0. Voltar

MENU

    read -r -p "Escolha uma opção: " sub_choice

    case "$sub_choice" in
      1)
        bash "$EXPORT_ENVIRONMENT"
        pause_menu
        ;;
      2)
        bash "$IMPORT_ENVIRONMENT" --dry-run
        pause_menu
        ;;
      3)
        bash "$IMPORT_ENVIRONMENT"
        pause_menu
        ;;
      4)
        bash "$COMPARE_ENVIRONMENT"
        pause_menu
        ;;
      5)
        if [[ -f "$CONFIG_LOCAL" ]]; then
          bash "$RUNTIME_CHECKER" --config "$CONFIG_LOCAL" --update-manifest --no-fail
        else
          echo "Configuração local não encontrada. Use a opção 18 do menu principal."
        fi
        pause_menu
        ;;
      6)
        bash "$RUNTIME_CHECKER" --preset portable --update-manifest --no-fail
        pause_menu
        ;;
      7)
        bash "$RUNTIME_CHECKER" --preset modern --update-manifest --no-fail
        pause_menu
        ;;
      0)
        return
        ;;
      *)
        echo "Opção inválida."
        sleep 1
        ;;
    esac
  done
}

show_menu() {
  clear || true
  cat <<MENU
====================================================
                 SUPER DEV KIT v$VERSION
====================================================

1.  Stack Wizard
2.  Dry-run do Stack Wizard
3.  Instalar por perfil
4.  Dry-run de um perfil
5.  Extensões VS Code por perfil
6.  Executar configuração JSON
7.  Dry-run da configuração JSON
8.  Dev Doctor
9.  Ver manifesto/estado local
10. Exportar inventário do ambiente
11. Atualizar Super Dev Kit
12. Preview de cleanup baseado no manifesto
13. Backup do VS Code
14. Preview de restore do VS Code
15. Backup da configuração Git
16. Preview de restore da configuração Git
17. Importar certificado CA (opcional)
18. Criar configuração local a partir do exemplo
19. Mostrar exemplos Docker
20. Ambientes reproduzíveis / lock file
0.  Sair

MENU
}

while true; do
  show_menu
  read -r -p "Escolha uma opção: " choice

  case "$choice" in
    1)
      bash "$STACK_WIZARD"
      pause_menu
      ;;
    2)
      bash "$STACK_WIZARD" --dry-run
      pause_menu
      ;;
    3)
      if profile="$(read_profile)"; then
        sudo bash "$INSTALLER" --profile "$profile"
      else
        echo "Perfil inválido."
      fi
      pause_menu
      ;;
    4)
      if profile="$(read_profile)"; then
        bash "$INSTALLER" --profile "$profile" --dry-run
      else
        echo "Perfil inválido."
      fi
      pause_menu
      ;;
    5)
      if profile="$(read_profile)"; then
        bash "$EXTENSIONS" --profile "$profile"
      else
        echo "Perfil inválido."
      fi
      pause_menu
      ;;
    6)
      if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo "Configuração local não encontrada."
        echo "Use a opção 18 primeiro."
      else
        bash "$CONFIG_RUNNER" --config "$CONFIG_LOCAL"
      fi
      pause_menu
      ;;
    7)
      if [[ ! -f "$CONFIG_LOCAL" ]]; then
        echo "Configuração local não encontrada."
      else
        bash "$CONFIG_RUNNER" --config "$CONFIG_LOCAL" --dry-run
      fi
      pause_menu
      ;;
    8)
      bash "$DOCTOR"
      pause_menu
      ;;
    9)
      bash "$SHOW_STATE"
      pause_menu
      ;;
    10)
      bash "$INVENTORY"
      pause_menu
      ;;
    11)
      bash "$UPDATER"
      pause_menu
      ;;
    12)
      bash "$CLEANUP"
      pause_menu
      ;;
    13)
      bash "$BACKUP_VSCODE"
      pause_menu
      ;;
    14)
      bash "$RESTORE_VSCODE"
      pause_menu
      ;;
    15)
      bash "$BACKUP_GIT"
      pause_menu
      ;;
    16)
      bash "$RESTORE_GIT"
      pause_menu
      ;;
    17)
      sudo bash "$CA_IMPORTER" --auto
      pause_menu
      ;;
    18)
      if [[ -f "$CONFIG_LOCAL" ]]; then
        echo "config/devkit.config.json já existe."
      else
        cp "$CONFIG_EXAMPLE" "$CONFIG_LOCAL"
        echo "[OK] Configuração criada:"
        echo "     $CONFIG_LOCAL"
      fi
      pause_menu
      ;;
    19)
      cat "$ROOT_DIR/examples/README.md"
      pause_menu
      ;;
    20)
      show_reproducibility_menu
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

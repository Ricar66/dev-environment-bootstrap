#!/usr/bin/env bash
set -Eeuo pipefail

# Super Dev Kit CLI orchestrator.
#
# Purpose:
#   Parse the public command contract and delegate execution to specialized
#   scripts. Installation logic belongs to modules/tools, not this file.
#
# Security:
#   Arguments are handled as arrays; this file intentionally avoids eval.
#   Destructive actions remain opt-in in their delegated tools.
#
# Public exit codes:
#   0 success, 1 operational failure, 2 drift/policy mismatch,
#   64 invalid usage, 69 unavailable dependency, 70 internal error.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
COMMANDS_FILE="$ROOT_DIR/cli/commands.json"

EXIT_USAGE=64
EXIT_UNAVAILABLE=69

get_version() {
  if [[ -f "$VERSION_FILE" ]]; then
    tr -d '\r\n' < "$VERSION_FILE"
  else
    printf 'dev'
  fi
}

json_envelope() {
  local command_name="$1"
  local exit_code="$2"
  local data_json="$3"
  local output_file="${4:-}"

  python3 - "$command_name" "$exit_code" "$data_json" "$output_file" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

command, exit_code, data_json, output_file = sys.argv[1:5]
code = int(exit_code)

payload = {
    "schema_version": 1,
    "command": command,
    "success": code == 0,
    "exit_code": code,
    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
}

if data_json:
    payload["data"] = json.loads(data_json)

if output_file and os.path.exists(output_file):
    with open(output_file, encoding="utf-8", errors="replace") as f:
        payload["output"] = [line.rstrip("\n") for line in f]

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
}

usage_error() {
  local message="$*"

  if [[ "${JSON_MODE:-0}" -eq 1 ]] && command -v python3 >/dev/null 2>&1; then
    local data
    data="$(python3 - "$message" <<'PY'
import json, sys
print(json.dumps({"error": sys.argv[1], "hint": "Use 'devkit help' para ver os comandos."}))
PY
)"
    json_envelope "${COMMAND:-cli}" "$EXIT_USAGE" "$data"
  else
    echo "Erro: $message" >&2
    echo "Use 'devkit help' para ver os comandos." >&2
  fi

  exit "$EXIT_USAGE"
}

show_help() {
  local topic="${1:-}"

  case "$topic" in
    setup)
      cat <<'EOF'
Uso:
  devkit setup [perfil] [--dry-run] [--auto-ca] [--ca ARQUIVO] [--yes]

Perfis:
  essential | frontend | backend | fullstack | datasql | devops
EOF
      ;;
    stack)
      cat <<'EOF'
Uso:
  devkit stack <nome> [--dry-run] [--skip-extensions]
EOF
      ;;
    project)
      cat <<'EOF'
Uso:
  devkit project list
  devkit project <template> <nome> [--output PASTA] [--dry-run]
                 [--force] [--with-devcontainer] [--install-deps]
EOF
      ;;
    runtime)
      cat <<'EOF'
Uso:
  devkit runtime list
  devkit runtime <runtime> <versao> [--manager auto] [--dry-run]

Runtimes:
  node | python | dotnet | java | php
EOF
      ;;
    import)
      cat <<'EOF'
Uso:
  devkit import [--lock ARQUIVO] [--dry-run] [--skip-extensions]
EOF
      ;;
    compare)
      cat <<'EOF'
Uso:
  devkit compare [--lock ARQUIVO]
EOF
      ;;
    backup)
      cat <<'EOF'
Uso:
  devkit backup <vscode|git>
EOF
      ;;
    cleanup)
      cat <<'EOF'
Uso:
  devkit cleanup [--apply] [--include-core] [--include-docker]
                 [--extensions-only] [--packages-only]

Descrição:
  Mostra um preview por padrão. --apply é necessário para remover itens.
EOF
      ;;
    doctor)
      cat <<'EOF'
Uso:
  devkit doctor [--verbose] [--json]

Descrição:
  Executa o check-up do ambiente e informa score, warnings, falhas e drift.
  --verbose mostra causa provável e comando de verificação para problemas.
EOF
      ;;
    state)
      cat <<'EOF'
Uso:
  devkit state [--json]

Descrição:
  Mostra o manifesto local .super-dev-kit/manifest.json.
EOF
      ;;
    export)
      cat <<'EOF'
Uso:
  devkit export [--output ARQUIVO] [--config ARQUIVO]

Descrição:
  Exporta a intenção do ambiente para um lock file portável.
EOF
      ;;
    inventory)
      cat <<'EOF'
Uso:
  devkit inventory

Descrição:
  Gera um inventário das ferramentas e versões detectadas.
EOF
      ;;
    update)
      cat <<'EOF'
Uso:
  devkit update

Descrição:
  Atualiza o clone com fast-forward e recusa mudanças locais não salvas.
EOF
      ;;
    info)
      cat <<'EOF'
Uso:
  devkit info [--json]

Descrição:
  Resume versão, plataforma, shell, Git, configuração, manifesto e CLI global.
  É somente leitura e não acessa serviços externos.
EOF
      ;;
    config)
      cat <<'EOF'
Uso:
  devkit config path [--config ARQUIVO]
  devkit config show [--config ARQUIVO]
  devkit config validate [--config ARQUIVO]

Descrição:
  Inspeciona o arquivo declarativo sem alterá-lo.
EOF
      ;;
    cli)
      cat <<'EOF'
Uso:
  devkit cli install
  devkit cli uninstall
  devkit cli status
EOF
      ;;
    *)
      cat <<EOF
Super Dev Kit CLI v$(get_version)

Uso:
  devkit <comando> [opcoes]
  devkit <comando> [opcoes] --json

Comandos:
  setup       Prepara a maquina por perfil
  doctor      Executa o Dev Doctor
  stack       Instala uma stack
  project     Lista ou gera projeto por template
  runtime     Usa adapters de version manager
  state       Mostra o manifesto local
  export      Exporta o ambiente para lock file
  import      Importa um lock file
  compare     Compara lock x maquina
  backup      Backup de VS Code ou Git
  inventory   Gera inventario
  cleanup     Cleanup controlado
  update      Atualiza o Super Dev Kit
  info        Resume a instalação atual
  config      Inspeciona/valida a configuração
  version     Mostra a versao
  commands    Lista os comandos
  cli         Instala/remove o comando global

Globais:
  --json      Emite envelope JSON quando suportado
  -h, --help  Mostra ajuda

Codigos de saida:
  0   sucesso
  1   falha operacional da ferramenta delegada
  2   drift/diferenca/politica nao atendida
  64  uso invalido da CLI
  69  dependencia ou recurso indisponivel
  70  erro interno da CLI
EOF
      ;;
  esac
}

invoke_tool() {
  local command_name="$1"
  local tool="$2"
  local json_mode="$3"
  local use_sudo="$4"
  shift 4
  local tool_args=("$@")

  if [[ ! -f "$tool" ]]; then
    if [[ "$json_mode" -eq 1 ]]; then
      json_envelope "$command_name" "$EXIT_UNAVAILABLE" "$(python3 -c 'import json,sys; print(json.dumps({"error":"Ferramenta nao encontrada.","path":sys.argv[1]}))' "$tool")"
    else
      echo "Ferramenta nao encontrada: $tool" >&2
    fi
    return "$EXIT_UNAVAILABLE"
  fi

  local runner=(bash "$tool")
  if [[ "$use_sudo" -eq 1 && "${EUID:-$(id -u)}" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      if [[ "$json_mode" -eq 1 ]]; then
        json_envelope "$command_name" "$EXIT_UNAVAILABLE" '{"error":"sudo nao encontrado."}'
      else
        echo "sudo nao encontrado; execute como root." >&2
      fi
      return "$EXIT_UNAVAILABLE"
    fi
    runner=(sudo bash "$tool")
  fi

  if [[ "$json_mode" -eq 1 ]]; then
    local tmp
    tmp="$(mktemp)"
    local code=0

    set +e
    "${runner[@]}" "${tool_args[@]}" >"$tmp" 2>&1
    code=$?
    set -e

    local data
    data="$(python3 - "$tool" "${tool_args[@]}" <<'PY'
import json
import sys
print(json.dumps({
    "delegated_to": sys.argv[1],
    "arguments": sys.argv[2:],
}, ensure_ascii=False))
PY
)"
    json_envelope "$command_name" "$code" "$data" "$tmp"
    rm -f "$tmp"
    return "$code"
  fi

  "${runner[@]}" "${tool_args[@]}"
}

JSON_MODE=0
ARGS=()

for item in "$@"; do
  if [[ "$item" == "--json" ]]; then
    JSON_MODE=1
  else
    ARGS+=("$item")
  fi
done

if [[ ${#ARGS[@]} -eq 0 ]]; then
  show_help
  exit 0
fi

case "${ARGS[0]}" in
  -h|--help)
    show_help
    exit 0
    ;;
  --version)
    ARGS=("version")
    ;;
esac

COMMAND="${ARGS[0],,}"
REST=("${ARGS[@]:1}")

if [[ "$COMMAND" == "help" ]]; then
  show_help "${REST[0]:-}"
  exit 0
fi

if [[ "$COMMAND" == "version" ]]; then
  [[ ${#REST[@]} -eq 0 ]] || usage_error "version nao aceita argumentos."
  version="$(get_version)"
  if [[ "$JSON_MODE" -eq 1 ]]; then
    json_envelope "version" 0 "$(python3 -c 'import json,sys; print(json.dumps({"version":sys.argv[1],"platform":"linux"}))' "$version")"
  else
    echo "$version"
  fi
  exit 0
fi

if [[ "$COMMAND" == "commands" ]]; then
  [[ ${#REST[@]} -eq 0 ]] || usage_error "commands nao aceita argumentos."
  [[ -f "$COMMANDS_FILE" ]] || { echo "Contrato de comandos nao encontrado: $COMMANDS_FILE" >&2; exit "$EXIT_UNAVAILABLE"; }

  if [[ "$JSON_MODE" -eq 1 ]]; then
    json_envelope "commands" 0 "$(cat "$COMMANDS_FILE")"
  else
    python3 - "$COMMANDS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for name, description in data["commands"].items():
    print(f"{name:<12} {description}")
PY
  fi
  exit 0
fi

if [[ "$COMMAND" == "state" && "$JSON_MODE" -eq 1 ]]; then
  [[ ${#REST[@]} -eq 0 ]] || usage_error "state nao aceita argumentos."
  manifest="$ROOT_DIR/.super-dev-kit/manifest.json"

  if [[ ! -f "$manifest" ]]; then
    json_envelope "state" 1 "$(python3 -c 'import json,sys; print(json.dumps({"error":"Manifesto local ainda nao existe.","path":sys.argv[1]}))' "$manifest")"
    exit 1
  fi

  python3 - "$manifest" <<'PY'
import json, sys
from datetime import datetime, timezone

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        state = json.load(f)
    payload = {
        "schema_version": 1,
        "command": "state",
        "success": True,
        "exit_code": 0,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "data": state,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
except Exception as exc:
    payload = {
        "schema_version": 1,
        "command": "state",
        "success": False,
        "exit_code": 70,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "data": {"error": f"Manifesto invalido: {exc}"},
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    raise SystemExit(70)
PY
  exit $?
fi

TOOL=""
TOOL_ARGS=()
USE_SUDO=0

case "$COMMAND" in
  setup)
    TOOL="$ROOT_DIR/linux/bootstrap-vm-ubuntu.sh"
    profile="essential"
    positional_used=0
    dry_run=0
    i=0

    while (( i < ${#REST[@]} )); do
      token="${REST[$i]}"
      case "$token" in
        --profile)
          (( i + 1 < ${#REST[@]} )) || usage_error "--profile exige um valor."
          profile="${REST[$((i+1))],,}"
          i=$((i+2))
          ;;
        --dry-run)
          TOOL_ARGS+=(--dry-run)
          dry_run=1
          i=$((i+1))
          ;;
        --auto-ca)
          TOOL_ARGS+=(--auto-ca)
          i=$((i+1))
          ;;
        --ca)
          (( i + 1 < ${#REST[@]} )) || usage_error "--ca exige um arquivo."
          TOOL_ARGS+=(--ca "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        --yes|--non-interactive)
          TOOL_ARGS+=(--yes)
          i=$((i+1))
          ;;
        --package)
          (( i + 1 < ${#REST[@]} )) || usage_error "--package exige um pacote."
          TOOL_ARGS+=(--package "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        -*)
          usage_error "Opcao desconhecida em setup: $token"
          ;;
        *)
          [[ "$positional_used" -eq 0 ]] || usage_error "Argumento inesperado em setup: $token"
          profile="${token,,}"
          positional_used=1
          i=$((i+1))
          ;;
      esac
    done

    case "$profile" in
      essential|frontend|backend|fullstack|datasql|devops) ;;
      *) usage_error "Perfil invalido: $profile" ;;
    esac

    TOOL_ARGS=(--profile "$profile" "${TOOL_ARGS[@]}")
    [[ "$dry_run" -eq 1 ]] || USE_SUDO=1
    ;;

  doctor)
    TOOL="$ROOT_DIR/diagnostics/dev-doctor.sh"
    for token in "${REST[@]}"; do
      case "$token" in
        --verbose) TOOL_ARGS+=(--verbose) ;;
        *) usage_error "Opcao desconhecida em doctor: $token" ;;
      esac
    done
    ;;

  stack)
    [[ ${#REST[@]} -ge 1 ]] || usage_error "Informe a stack. Ex.: devkit stack react"
    TOOL="$ROOT_DIR/tools/install-stack.sh"
    TOOL_ARGS=(--stack "${REST[0]}")
    for token in "${REST[@]:1}"; do
      case "$token" in
        --dry-run) TOOL_ARGS+=(--dry-run) ;;
        --skip-extensions) TOOL_ARGS+=(--skip-extensions) ;;
        *) usage_error "Opcao desconhecida em stack: $token" ;;
      esac
    done
    ;;

  project)
    TOOL="$ROOT_DIR/tools/create-project.sh"

    if [[ ${#REST[@]} -eq 1 && "${REST[0]}" == "list" ]]; then
      TOOL_ARGS=(--list)
    else
      [[ ${#REST[@]} -ge 2 ]] || usage_error "Use: devkit project <template> <nome> [opcoes]"
      TOOL_ARGS=(--template "${REST[0]}" --name "${REST[1]}")
      i=2

      while (( i < ${#REST[@]} )); do
        token="${REST[$i]}"
        case "$token" in
          --output)
            (( i + 1 < ${#REST[@]} )) || usage_error "--output exige uma pasta."
            TOOL_ARGS+=(--output "${REST[$((i+1))]}")
            i=$((i+2))
            ;;
          --dry-run) TOOL_ARGS+=(--dry-run); i=$((i+1)) ;;
          --force) TOOL_ARGS+=(--force); i=$((i+1)) ;;
          --with-devcontainer) TOOL_ARGS+=(--with-devcontainer); i=$((i+1)) ;;
          --install-deps) TOOL_ARGS+=(--install-deps); i=$((i+1)) ;;
          *) usage_error "Opcao desconhecida em project: $token" ;;
        esac
      done
    fi
    ;;

  runtime)
    TOOL="$ROOT_DIR/tools/runtime-manager.sh"

    if [[ ${#REST[@]} -eq 1 && "${REST[0]}" == "list" ]]; then
      TOOL_ARGS=(--list)
    else
      [[ ${#REST[@]} -ge 2 ]] || usage_error "Use: devkit runtime <runtime> <versao> [--manager auto] [--dry-run]"
      TOOL_ARGS=(--runtime "${REST[0]}" --version "${REST[1]}")
      i=2

      while (( i < ${#REST[@]} )); do
        token="${REST[$i]}"
        case "$token" in
          --manager)
            (( i + 1 < ${#REST[@]} )) || usage_error "--manager exige um valor."
            TOOL_ARGS+=(--manager "${REST[$((i+1))]}")
            i=$((i+2))
            ;;
          --dry-run) TOOL_ARGS+=(--dry-run); i=$((i+1)) ;;
          *) usage_error "Opcao desconhecida em runtime: $token" ;;
        esac
      done
    fi
    ;;

  state)
    [[ ${#REST[@]} -eq 0 ]] || usage_error "state nao aceita argumentos."
    TOOL="$ROOT_DIR/tools/show-state.sh"
    ;;

  export)
    TOOL="$ROOT_DIR/tools/export-environment.sh"
    i=0
    while (( i < ${#REST[@]} )); do
      token="${REST[$i]}"
      case "$token" in
        --output)
          (( i + 1 < ${#REST[@]} )) || usage_error "--output exige um arquivo."
          TOOL_ARGS+=(--output "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        --config)
          (( i + 1 < ${#REST[@]} )) || usage_error "--config exige um arquivo."
          TOOL_ARGS+=(--config "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        *) usage_error "Opcao desconhecida em export: $token" ;;
      esac
    done
    ;;

  import)
    TOOL="$ROOT_DIR/tools/import-environment.sh"
    i=0
    while (( i < ${#REST[@]} )); do
      token="${REST[$i]}"
      case "$token" in
        --lock)
          (( i + 1 < ${#REST[@]} )) || usage_error "--lock exige um arquivo."
          TOOL_ARGS+=(--lock "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        --dry-run) TOOL_ARGS+=(--dry-run); i=$((i+1)) ;;
        --skip-extensions) TOOL_ARGS+=(--skip-extensions); i=$((i+1)) ;;
        *) usage_error "Opcao desconhecida em import: $token" ;;
      esac
    done
    ;;

  compare)
    TOOL="$ROOT_DIR/tools/compare-environment.sh"
    i=0
    while (( i < ${#REST[@]} )); do
      token="${REST[$i]}"
      case "$token" in
        --lock)
          (( i + 1 < ${#REST[@]} )) || usage_error "--lock exige um arquivo."
          TOOL_ARGS+=(--lock "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        *) usage_error "Opcao desconhecida em compare: $token" ;;
      esac
    done
    ;;

  backup)
    [[ ${#REST[@]} -eq 1 ]] || usage_error "Use: devkit backup <vscode|git>"
    case "${REST[0],,}" in
      vscode) TOOL="$ROOT_DIR/tools/backup-vscode.sh" ;;
      git) TOOL="$ROOT_DIR/tools/backup-git.sh" ;;
      *) usage_error "Backup invalido: ${REST[0]}" ;;
    esac
    ;;

  inventory)
    [[ ${#REST[@]} -eq 0 ]] || usage_error "inventory nao aceita argumentos."
    TOOL="$ROOT_DIR/tools/inventory.sh"
    ;;

  cleanup)
    TOOL="$ROOT_DIR/tools/cleanup.sh"
    apply=0
    for token in "${REST[@]}"; do
      case "$token" in
        --apply) TOOL_ARGS+=(--apply); apply=1 ;;
        --include-core) TOOL_ARGS+=(--include-core) ;;
        --include-docker) TOOL_ARGS+=(--include-docker) ;;
        --extensions-only) TOOL_ARGS+=(--extensions-only) ;;
        --packages-only) TOOL_ARGS+=(--packages-only) ;;
        *) usage_error "Opcao desconhecida em cleanup: $token" ;;
      esac
    done
    [[ "$apply" -eq 1 ]] && USE_SUDO=1
    ;;

  update)
    [[ ${#REST[@]} -eq 0 ]] || usage_error "update nao aceita argumentos."
    TOOL="$ROOT_DIR/tools/update-devkit.sh"
    ;;

  info)
    [[ ${#REST[@]} -eq 0 ]] || usage_error "info nao aceita argumentos."
    TOOL="$ROOT_DIR/tools/devkit-info.sh"
    ;;

  config)
    [[ ${#REST[@]} -ge 1 ]] || usage_error "Use: devkit config <path|show|validate> [--config ARQUIVO]"
    action="${REST[0],,}"
    case "$action" in
      path|show|validate) ;;
      *) usage_error "Acao de config invalida: $action" ;;
    esac

    TOOL="$ROOT_DIR/tools/devkit-config.sh"
    TOOL_ARGS=("$action")
    i=1

    while (( i < ${#REST[@]} )); do
      token="${REST[$i]}"
      case "$token" in
        --config)
          (( i + 1 < ${#REST[@]} )) || usage_error "--config exige um arquivo."
          TOOL_ARGS+=(--config "${REST[$((i+1))]}")
          i=$((i+2))
          ;;
        *) usage_error "Opcao desconhecida em config: $token" ;;
      esac
    done
    ;;

  cli)
    [[ ${#REST[@]} -eq 1 ]] || usage_error "Use: devkit cli <install|uninstall|status>"
    case "${REST[0],,}" in
      install)
        TOOL="$ROOT_DIR/tools/install-cli.sh"
        ;;
      uninstall)
        TOOL="$ROOT_DIR/tools/uninstall-cli.sh"
        ;;
      status)
        shim="$HOME/.local/bin/devkit"
        installed=false
        in_path=false
        [[ -L "$shim" || -f "$shim" ]] && installed=true
        case ":$PATH:" in *":$HOME/.local/bin:"*) in_path=true ;; esac
        code=1
        [[ "$installed" == "true" ]] && code=0

        if [[ "$JSON_MODE" -eq 1 ]]; then
          data="$(python3 - "$installed" "$shim" "$in_path" <<'PY'
import json, sys
print(json.dumps({
    "installed": sys.argv[1] == "true",
    "shim": sys.argv[2],
    "in_path": sys.argv[3] == "true",
}))
PY
)"
          json_envelope "cli status" "$code" "$data"
        else
          echo "Shim: $shim"
          echo "Instalado: $installed"
          echo "No PATH da sessao atual: $in_path"
        fi
        exit "$code"
        ;;
      *) usage_error "Acao de CLI invalida: ${REST[0]}" ;;
    esac
    ;;

  *)
    usage_error "Comando desconhecido: $COMMAND"
    ;;
esac

set +e
invoke_tool "$COMMAND" "$TOOL" "$JSON_MODE" "$USE_SUDO" "${TOOL_ARGS[@]}"
CODE=$?
set -e
exit "$CODE"

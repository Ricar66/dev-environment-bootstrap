#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME=""
VERSION=""
MANAGER="auto"
DRY_RUN=0
LIST=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/runtime-manager.sh --list
  bash tools/runtime-manager.sh --runtime node --version 22 --manager auto --dry-run

O script usa apenas version managers já instalados. Ele não baixa managers automaticamente.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime)
      RUNTIME="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --manager)
      MANAGER="${2:-auto}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --list)
      LIST=1
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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT_DIR/versions/managers.json"

[[ -f "$CATALOG" ]] || { echo "Catálogo não encontrado: $CATALOG"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

manager_command() {
  local name="$1"
  case "$name" in
    sdkman) echo "sdk" ;;
    dotnet-install) echo "dotnet-install" ;;
    *) echo "$name" ;;
  esac
}

manager_available() {
  local command_name
  command_name="$(manager_command "$1")"
  command -v "$command_name" >/dev/null 2>&1
}

if [[ "$LIST" -eq 1 ]]; then
  python3 - "$CATALOG" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)["runtimes"]
for key, value in data.items():
    print(f"{key}|{value['display_name']}|{'|'.join(value.get('managers', []))}|{value.get('fallback','native')}")
PY
  exit 0
fi

case "$RUNTIME" in
  node|python|dotnet|java|php) ;;
  *)
    echo "Runtime inválido: $RUNTIME"
    usage
    exit 1
    ;;
esac

[[ -n "$VERSION" ]] || { echo "Informe --version."; exit 1; }

if [[ ! "$VERSION" =~ ^[A-Za-z0-9._+-]+$ ]]; then
  echo "Versão inválida."
  exit 1
fi

mapfile -t runtime_data < <(
  python3 - "$CATALOG" "$RUNTIME" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    runtime = json.load(f)["runtimes"].get(sys.argv[2])
if runtime is None:
    raise SystemExit(1)
print(runtime["display_name"])
for manager in runtime.get("managers", []):
    print(manager)
PY
)

[[ ${#runtime_data[@]} -gt 0 ]] || { echo "Runtime não encontrado."; exit 1; }
DISPLAY_NAME="${runtime_data[0]}"
CANDIDATES=("${runtime_data[@]:1}")

selected="${MANAGER,,}"

if [[ "$selected" == "auto" ]]; then
  selected="native"
  for candidate in "${CANDIDATES[@]}"; do
    if manager_available "$candidate"; then
      selected="$candidate"
      break
    fi
  done
elif [[ "$selected" != "native" ]]; then
  supported=0
  for candidate in "${CANDIDATES[@]}"; do
    [[ "$candidate" == "$selected" ]] && supported=1
  done
  [[ "$supported" -eq 1 ]] || { echo "Manager '$selected' não é suportado para $RUNTIME."; exit 1; }
fi

echo "Runtime: $DISPLAY_NAME"
echo "Versão:  $VERSION"
echo "Manager: $selected"
echo

if [[ "$selected" == "native" ]]; then
  echo "[FALLBACK] Nenhum version manager compatível foi selecionado/detectado."
  echo "O Super Dev Kit não baixa version managers automaticamente."
  echo "Use a instalação nativa da stack e valide com check-runtime-versions."
  exit 0
fi

if [[ "$DRY_RUN" -ne 1 ]] && ! manager_available "$selected"; then
  echo "Manager '$selected' não está disponível nesta sessão."
  exit 2
fi

run_command() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[DRY-RUN]'
    printf ' %q' "$@"
    echo
  else
    echo "[EXEC] $*"
    "$@"
  fi
}

case "$selected" in
  fnm)
    run_command fnm install "$VERSION"
    run_command fnm default "$VERSION"
    ;;
  nvm)
    run_command nvm install "$VERSION"
    run_command nvm use "$VERSION"
    ;;
  pyenv)
    run_command pyenv install -s "$VERSION"
    run_command pyenv global "$VERSION"
    ;;
  dotnet-install)
    run_command dotnet-install --version "$VERSION"
    ;;
  sdkman)
    run_command sdk install java "$VERSION"
    run_command sdk default java "$VERSION"
    ;;
  phpenv)
    run_command phpenv install -s "$VERSION"
    run_command phpenv global "$VERSION"
    ;;
  *)
    echo "Adapter não implementado: $selected"
    exit 1
    ;;
esac

echo
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[OK] Plano do version manager validado."
else
  echo "[OK] Runtime processado pelo adapter '$selected'."
  echo "Abra uma nova sessão de terminal se o manager exigir recarga do ambiente."
fi

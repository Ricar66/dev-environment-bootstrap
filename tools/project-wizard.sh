#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT_DIR/templates/catalog.json"
GENERATOR="$ROOT_DIR/tools/create-project.sh"

command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

mapfile -t templates < <(
  python3 - "$CATALOG" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    templates = json.load(f)["templates"]
for key in sorted(templates):
    item = templates[key]
    print(f"{key}|{item['name']}|{item['description']}")
PY
)

echo "================================================"
echo "          SUPER DEV KIT - PROJECT WIZARD"
echo "================================================"
echo

for i in "${!templates[@]}"; do
  IFS='|' read -r key name description <<< "${templates[$i]}"
  echo "$((i + 1)). $name"
  echo "   $description"
done

echo
read -r -p "Escolha um template: " choice

[[ "$choice" =~ ^[0-9]+$ ]] || { echo "Seleção inválida."; exit 1; }
index=$((choice - 1))
(( index >= 0 && index < ${#templates[@]} )) || { echo "Seleção inválida."; exit 1; }

IFS='|' read -r template_key template_name template_description <<< "${templates[$index]}"

read -r -p "Nome do projeto: " project_name
[[ -n "$project_name" ]] || { echo "Nome do projeto é obrigatório."; exit 1; }

read -r -p "Pasta de destino base [.]: " output_path
output_path="${output_path:-.}"

read -r -p "Adicionar Dev Container? (s/N): " devcontainer_answer
read -r -p "Instalar dependências após gerar? (s/N): " install_answer

args=(
  --template "$template_key"
  --name "$project_name"
  --output "$output_path"
)

[[ "$DRY_RUN" -eq 1 ]] && args+=(--dry-run)
[[ "$devcontainer_answer" =~ ^([sS]|[sS][iI][mM]|[yY]|[yY][eE][sS])$ ]] && args+=(--with-devcontainer)
[[ "$install_answer" =~ ^([sS]|[sS][iI][mM]|[yY]|[yY][eE][sS])$ ]] && args+=(--install-deps)

echo
bash "$GENERATOR" "${args[@]}"

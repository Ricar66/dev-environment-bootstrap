#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_DIR="$ROOT_DIR/stacks"
INSTALLER="$ROOT_DIR/tools/install-stack.sh"

command -v python3 >/dev/null 2>&1 || {
  echo "python3 é necessário para o wizard."
  exit 1
}

mapfile -t files < <(find "$STACK_DIR" -maxdepth 1 -type f -name '*.json' | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Nenhuma stack encontrada."
  exit 1
fi

echo "================================================"
echo "          SUPER DEV KIT - STACK WIZARD"
echo "================================================"
echo

for i in "${!files[@]}"; do
  name="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["name"])' "${files[$i]}")"
  description="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get("description",""))' "${files[$i]}")"
  echo "$((i + 1)). $name"
  echo "   $description"
done

echo
read -r -p "Escolha uma stack: " choice

[[ "$choice" =~ ^[0-9]+$ ]] || { echo "Seleção inválida."; exit 1; }

index=$((choice - 1))
(( index >= 0 && index < ${#files[@]} )) || { echo "Seleção inválida."; exit 1; }

slug="$(basename "${files[$index]}" .json)"
args=(--stack "$slug")
[[ "$DRY_RUN" -eq 1 ]] && args+=(--dry-run)

bash "$INSTALLER" "${args[@]}"

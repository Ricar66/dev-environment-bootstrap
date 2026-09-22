#!/usr/bin/env bash
set -Eeuo pipefail

TEMPLATE=""
NAME=""
OUTPUT_PATH="."
DRY_RUN=0
FORCE=0
WITH_DEVCONTAINER=0
INSTALL_DEPENDENCIES=0
LIST=0

usage() {
  cat <<'EOF'
Uso:
  bash tools/create-project.sh --list
  bash tools/create-project.sh --template react-vite --name meu-app --dry-run
  bash tools/create-project.sh --template react-vite --name meu-app --with-devcontainer
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      TEMPLATE="${2:-}"
      shift 2
      ;;
    --name)
      NAME="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-.}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --with-devcontainer)
      WITH_DEVCONTAINER=1
      shift
      ;;
    --install-deps)
      INSTALL_DEPENDENCIES=1
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
CATALOG="$ROOT_DIR/templates/catalog.json"

[[ -f "$CATALOG" ]] || { echo "Catálogo não encontrado: $CATALOG"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 é necessário."; exit 1; }

if [[ "$LIST" -eq 1 ]]; then
  python3 - "$CATALOG" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)["templates"]
for key in sorted(data):
    item = data[key]
    print(f"{key} — {item['name']}")
    print(f"  {item['description']}")
    print()
PY
  exit 0
fi

[[ -n "$TEMPLATE" && -n "$NAME" ]] || {
  echo "Informe --template e --name, ou use --list."
  exit 1
}

if [[ "$OUTPUT_PATH" != /* ]]; then
  OUTPUT_PATH="$(pwd)/$OUTPUT_PATH"
fi

set +e
TARGET_DIR="$(
  python3 - "$ROOT_DIR" "$CATALOG" "$TEMPLATE" "$NAME" "$OUTPUT_PATH"     "$DRY_RUN" "$FORCE" "$WITH_DEVCONTAINER" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

root, catalog_path, template_key, project_name, output_path = sys.argv[1:6]
dry_run = sys.argv[6] == "1"
force = sys.argv[7] == "1"
with_devcontainer = sys.argv[8] == "1"

with open(catalog_path, encoding="utf-8") as f:
    catalog = json.load(f)["templates"]

if template_key not in catalog:
    print(f"Template não encontrado: {template_key}", file=sys.stderr)
    raise SystemExit(2)

item = catalog[template_key]
slug = project_name.strip().lower()
slug = re.sub(r"[^a-z0-9._-]+", "-", slug)
slug = re.sub(r"-{2,}", "-", slug).strip("-._")

if not slug:
    print("Não foi possível gerar um nome de projeto válido.", file=sys.stderr)
    raise SystemExit(2)

source = Path(root) / item["source"]
target = Path(output_path).expanduser().resolve() / slug

if not source.is_dir():
    print(f"Pasta do template não encontrada: {source}", file=sys.stderr)
    raise SystemExit(2)

if target.exists() and any(target.iterdir()) and not force:
    print(
        "O destino já existe e não está vazio. Use --force para sobrescrita controlada.",
        file=sys.stderr,
    )
    raise SystemExit(2)

files = [path for path in source.rglob("*") if path.is_file()]

print("================================================", file=sys.stderr)
print("       SUPER DEV KIT - CREATE PROJECT", file=sys.stderr)
print("================================================", file=sys.stderr)
print("", file=sys.stderr)
print(f"Template:     {item['name']}", file=sys.stderr)
print(f"Nome:         {project_name}", file=sys.stderr)
print(f"Slug:         {slug}", file=sys.stderr)
print(f"Destino:      {target}", file=sys.stderr)
print(f"DevContainer: {with_devcontainer}", file=sys.stderr)
print("", file=sys.stderr)
print("Arquivos:", file=sys.stderr)

for source_file in files:
    relative = source_file.relative_to(source)
    rendered_relative = str(relative).replace("__PROJECT_NAME__", slug)
    print(f"  - {rendered_relative}", file=sys.stderr)

if with_devcontainer:
    print("  - .devcontainer/devcontainer.json", file=sys.stderr)

print("  - .devkit-project.json", file=sys.stderr)

if dry_run:
    print("", file=sys.stderr)
    print("[DRY-RUN] Nenhum arquivo foi criado.", file=sys.stderr)
    print(str(target))
    raise SystemExit(0)

target.mkdir(parents=True, exist_ok=True)

for source_file in files:
    relative = source_file.relative_to(source)
    rendered_relative = str(relative).replace("__PROJECT_NAME__", slug)
    destination = target / rendered_relative
    destination.parent.mkdir(parents=True, exist_ok=True)

    if destination.exists() and not force:
        print(f"Arquivo já existe: {destination}", file=sys.stderr)
        raise SystemExit(2)

    content = source_file.read_text(encoding="utf-8")
    content = content.replace("{{PROJECT_NAME}}", project_name)
    content = content.replace("{{PROJECT_SLUG}}", slug)
    destination.write_text(content, encoding="utf-8")

if with_devcontainer:
    devcontainer_dir = target / ".devcontainer"
    devcontainer_dir.mkdir(parents=True, exist_ok=True)
    devcontainer = {
        "name": f"{project_name} Dev Container",
        "image": item["devcontainer_image"],
    }
    (devcontainer_dir / "devcontainer.json").write_text(
        json.dumps(devcontainer, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

metadata = {
    "schema_version": 1,
    "template": template_key,
    "project_name": project_name,
    "project_slug": slug,
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "generated_by": "Super Dev Kit",
    "devcontainer": with_devcontainer,
}
(target / ".devkit-project.json").write_text(
    json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)

print(str(target))
PY
)"
GENERATOR_RC=$?
set -e

if [[ "$GENERATOR_RC" -ne 0 ]]; then
  exit "$GENERATOR_RC"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  if [[ "$INSTALL_DEPENDENCIES" -eq 1 ]]; then
    echo "[DRY-RUN] Dependências seriam instaladas após a geração."
  fi
  exit 0
fi

run_with_retry() {
  local attempt
  for attempt in 1 2 3; do
    echo "[EXEC $attempt/3] $*"
    if "$@"; then
      return 0
    fi

    if [[ "$attempt" -lt 3 ]]; then
      echo "Tentativa falhou; tentando novamente em 3 segundos..."
      sleep 3
    fi
  done

  echo "Falha após 3 tentativas: $*"
  return 1
}

if [[ "$INSTALL_DEPENDENCIES" -eq 1 ]]; then
  case "$TEMPLATE" in
    react-vite|node-nest)
      command -v npm >/dev/null 2>&1 || { echo "npm não encontrado."; exit 2; }
      (cd "$TARGET_DIR" && run_with_retry npm install)
      ;;
    dotnet-webapi)
      command -v dotnet >/dev/null 2>&1 || { echo "dotnet não encontrado."; exit 2; }
      (cd "$TARGET_DIR" && run_with_retry dotnet restore)
      ;;
    python-api)
      command -v python3 >/dev/null 2>&1 || { echo "python3 não encontrado."; exit 2; }
      (cd "$TARGET_DIR" && run_with_retry python3 -m pip install -r requirements.txt)
      ;;
    docker-compose)
      echo "Nenhuma dependência local para instalar."
      ;;
  esac
fi

echo
echo "[OK] Projeto criado com sucesso."
echo "     $TARGET_DIR"

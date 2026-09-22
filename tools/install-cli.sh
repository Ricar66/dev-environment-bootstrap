#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT_DIR/devkit.sh"
BIN_DIR="$HOME/.local/bin"
SHIM="$BIN_DIR/devkit"

[[ -f "$LAUNCHER" ]] || { echo "Launcher raiz não encontrado: $LAUNCHER"; exit 1; }

mkdir -p "$BIN_DIR"

cat > "$SHIM" <<EOF
#!/usr/bin/env bash
# Super Dev Kit shim - managed by devkit cli install
exec bash "$LAUNCHER" "\$@"
EOF

chmod +x "$SHIM"

echo "[OK] CLI instalada:"
echo "     $SHIM"
echo

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "O diretório já está no PATH desta sessão."
    ;;
  *)
    echo "Adicione ~/.local/bin ao PATH caso sua distribuição ainda não faça isso."
    echo "Exemplo para Bash:"
    echo "  echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    ;;
esac

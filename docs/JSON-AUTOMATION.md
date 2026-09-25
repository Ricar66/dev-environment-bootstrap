# Automação com saída JSON

A CLI pode produzir um envelope JSON para integração com scripts, CI e ferramentas internas.

## Versão

~~~text
devkit version --json
~~~

Exemplo:

~~~json
{
  "schema_version": 1,
  "command": "version",
  "success": true,
  "exit_code": 0,
  "timestamp": "2026-09-22T15:00:00Z",
  "data": {
    "version": "0.9.0",
    "platform": "linux"
  }
}
~~~

## Estado

~~~text
devkit state --json
~~~

O campo data recebe o manifesto local.

## Scripts delegados

~~~text
devkit stack react --dry-run --json
~~~

A CLI preserva a saída textual da ferramenta delegada em output.

~~~json
{
  "schema_version": 1,
  "command": "stack",
  "success": true,
  "exit_code": 0,
  "data": {
    "delegated_to": "tools/install-stack.sh",
    "arguments": ["--stack", "react", "--dry-run"]
  },
  "output": [
    "Stack: React",
    "[DRY-RUN] ..."
  ]
}
~~~

## Bash + jq

~~~bash
version="$(devkit version --json | jq -r '.data.version')"
echo "$version"
~~~

## PowerShell

~~~powershell
$result = devkit version --json | ConvertFrom-Json
$result.data.version
~~~

## CMD

CMD não possui parser JSON nativo robusto. Para automação estruturada no Windows, prefira PowerShell.

~~~cmd
powershell -NoProfile -Command "devkit version --json | ConvertFrom-Json"
~~~

## Códigos de saída

O JSON não substitui o exit code do processo.

~~~bash
set +e
devkit compare --json > result.json
code=$?
set -e

echo "exit=$code"
jq . result.json
~~~

Consulte [CLI.md](CLI.md) para os códigos documentados.

## Schema formal

O envelope público da linha v1 possui JSON Schema versionado em:

~~~text
schemas/cli-envelope-v1.schema.json
~~~

Os demais formatos públicos também estão documentados em [SCHEMAS.md](SCHEMAS.md).

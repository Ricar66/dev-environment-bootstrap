# CLI unificada — v0.8

A v0.8 adiciona uma interface única para os recursos que já existiam no Super Dev Kit.

A CLI **não reimplementa** instaladores, stacks, templates ou diagnósticos. Ela funciona como uma camada de orquestração sobre os scripts já testados.

## Primeira execução

Sem instalar nada globalmente, use o launcher da raiz.

### CMD

~~~cmd
devkit.cmd version
devkit.cmd help
~~~

### PowerShell

~~~powershell
.\devkit.ps1 version
.\devkit.ps1 help
~~~

### Linux

~~~bash
bash devkit.sh version
bash devkit.sh help
~~~

## Instalar o comando global

### Windows

CMD:

~~~cmd
devkit.cmd cli install
~~~

PowerShell:

~~~powershell
.\devkit.ps1 cli install
~~~

O shim é criado em:

~~~text
%LOCALAPPDATA%\SuperDevKit\bin\devkit.cmd
~~~

O instalador adiciona esse diretório ao PATH do usuário quando necessário. Abra um novo terminal depois da primeira instalação.

### Linux

~~~bash
bash devkit.sh cli install
~~~

O shim é criado em:

~~~text
~/.local/bin/devkit
~~~

Se ~/.local/bin ainda não estiver no PATH, o instalador mostra o comando necessário.

Depois disso:

~~~text
devkit version
devkit help
~~~

## Comandos principais

~~~text
devkit setup
devkit doctor
devkit stack
devkit project
devkit runtime
devkit state
devkit export
devkit import
devkit compare
devkit backup
devkit inventory
devkit cleanup
devkit update
~~~

## Setup

Windows:

~~~text
devkit setup fullstack --dry-run
devkit setup fullstack
devkit setup backend --docker --wsl
~~~

Linux:

~~~text
devkit setup fullstack --dry-run
devkit setup fullstack
devkit setup datasql --auto-ca
~~~

A CLI traduz esses argumentos para o instalador nativo de cada plataforma.

## Stack

~~~text
devkit stack react --dry-run
devkit stack fullstack-react-node
~~~

## Project

Listar templates:

~~~text
devkit project list
~~~

Gerar:

~~~text
devkit project react-vite meu-app --dry-run
devkit project react-vite meu-app --with-devcontainer
~~~

Diretório base customizado:

~~~text
devkit project python-api minha-api --output ./projects
~~~

## Runtime

Listar adapters:

~~~text
devkit runtime list
~~~

Dry-run:

~~~text
devkit runtime node 22 --manager fnm --dry-run
~~~

## Estado e ambientes reproduzíveis

~~~text
devkit state
devkit export
devkit import --dry-run
devkit compare
~~~

Com lock específico:

~~~text
devkit import --lock ./meu-ambiente.lock.json --dry-run
devkit compare --lock ./meu-ambiente.lock.json
~~~

## Backup

~~~text
devkit backup vscode
devkit backup git
~~~

## Cleanup

Preview seguro:

~~~text
devkit cleanup
~~~

Aplicar:

~~~text
devkit cleanup --apply
~~~

O comportamento de segurança continua sendo definido pelo cleanup baseado no manifesto.

## Saída JSON

A opção global --json cria um envelope padronizado para automações.

Exemplos:

~~~text
devkit version --json
devkit commands --json
devkit state --json
devkit doctor --json
devkit stack react --dry-run --json
~~~

Exemplo de envelope:

~~~json
{
  "schema_version": 1,
  "command": "version",
  "success": true,
  "exit_code": 0,
  "timestamp": "2026-09-22T15:00:00Z",
  "data": {
    "version": "0.8.0",
    "platform": "linux"
  }
}
~~~

Para scripts legados que ainda produzem texto, a CLI preserva a saída dentro do campo output.

Assim a v0.8 adiciona automação sem obrigar a reescrever de uma vez toda a base já validada.

## Códigos de saída

| Código | Significado |
| ---: | --- |
| 0 | sucesso |
| 1 | falha operacional da ferramenta delegada |
| 2 | drift, diferença de ambiente ou política não atendida |
| 64 | uso inválido da CLI |
| 69 | dependência ou recurso indisponível |
| 70 | erro interno da CLI |

Os códigos existentes dos scripts delegados são preservados sempre que possível.

## Compatibilidade com comandos antigos

Nada foi removido.

Estes fluxos continuam funcionando:

~~~text
setup.cmd
.\setup.ps1
bash setup.sh

tools\install-stack.cmd
.\tools\install-stack.ps1
bash tools/install-stack.sh
~~~

A CLI é uma camada nova por cima deles.

## Descoberta

Ajuda geral:

~~~text
devkit help
~~~

Ajuda de um comando:

~~~text
devkit help project
devkit help runtime
devkit help cleanup
~~~

Lista de comandos em formato humano:

~~~text
devkit commands
~~~

Formato estruturado:

~~~text
devkit commands --json
~~~

## Remover o shim global

Windows:

~~~text
devkit cli uninstall
~~~

Linux:

~~~text
devkit cli uninstall
~~~

A remoção verifica se o arquivo encontrado foi criado pelo Super Dev Kit antes de apagá-lo.

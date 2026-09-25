# CLI unificada — v1

Na linha v1, `devkit` é a interface pública principal do Super Dev Kit.

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

O shim aponta para **este clone** do repositório. Se o diretório do clone for movido ou removido, execute novamente `devkit cli install` a partir da nova localização.

O instalador adiciona esse diretório ao PATH do usuário quando necessário. Abra um novo terminal depois da primeira instalação.

### Linux

~~~bash
bash devkit.sh cli install
~~~

O shim é criado em:

~~~text
~/.local/bin/devkit
~~~

Assim como no Windows, o shim aponta para o clone atual. Se você mover o repositório, reinstale o shim.

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
devkit info
devkit config
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

## Doctor

Check-up padrão:

~~~text
devkit doctor
~~~

Mais contexto para warnings e falhas:

~~~text
devkit doctor --verbose
~~~

Saída estruturada do Doctor v3:

~~~text
devkit doctor --json
~~~

O JSON inclui `health`, score, resumo e a lista de checks com detalhe, causa, sugestão e comando de verificação quando disponíveis.

Veja [DEV-DOCTOR.md](DEV-DOCTOR.md).

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

## Info

Resumo somente leitura da instalação atual:

~~~text
devkit info
~~~

Inclui versão do kit, plataforma, shell, branch/commit do clone, caminhos de configuração e manifesto e status do shim global.

Também pode ser usado com a opção global JSON:

~~~text
devkit info --json
~~~

Como `info` é uma ferramenta delegada nesta fase, o envelope JSON preserva a saída humana no campo `output`.

## Config

Descobrir o caminho padrão:

~~~text
devkit config path
~~~

Exibir o arquivo atual:

~~~text
devkit config show
~~~

Validar sintaxe e regras básicas:

~~~text
devkit config validate
~~~

Usar outro arquivo:

~~~text
devkit config validate --config ./config/minha-config.json
~~~

`config` é somente leitura: ele não cria nem altera o arquivo.

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
    "version": "1.0.0",
    "platform": "linux"
  }
}
~~~

Para scripts legados que ainda produzem texto, a CLI preserva a saída dentro do campo output.

A linha v1 preserva esse comportamento para manter compatibilidade com scripts já validados.

## Contrato estável da v1

Na linha v1, nomes dos comandos principais, códigos documentados e o envelope JSON schema_version 1 são tratados como contrato público. Mudanças incompatíveis exigem nova versão MAJOR.

Veja [VERSIONING.md](VERSIONING.md).

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

## Migração dos comandos antigos

A CLI não exige migração imediata. Os comandos antigos continuam válidos, mas existe uma equivalência direta:

| Antes | CLI v1 |
| --- | --- |
| `setup.cmd` / `.\setup.ps1` / `bash setup.sh` | `devkit setup` |
| `diagnostics/dev-doctor.*` | `devkit doctor` |
| `tools/install-stack.*` | `devkit stack <nome>` |
| `tools/create-project.*` | `devkit project <template> <nome>` |
| `tools/runtime-manager.*` | `devkit runtime <runtime> <versao>` |
| `tools/show-state.*` | `devkit state` |
| `tools/export-environment.*` | `devkit export` |
| `tools/import-environment.*` | `devkit import` |
| `tools/compare-environment.*` | `devkit compare` |
| `tools/backup-vscode.*` | `devkit backup vscode` |
| `tools/backup-git.*` | `devkit backup git` |
| `tools/inventory.*` | `devkit inventory` |
| `tools/cleanup.*` | `devkit cleanup` |
| `tools/update-devkit.*` | `devkit update` |

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

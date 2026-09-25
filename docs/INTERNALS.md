# Internals — Super Dev Kit

Este documento explica **como o projeto funciona por dentro**. Ele é voltado a quem mantém o código, revisa pull requests ou quer contribuir sem precisar descobrir a arquitetura lendo todos os scripts.

## Princípio central

A CLI deve ser fina.

`devkit` interpreta a intenção do usuário, valida argumentos e delega para ferramentas especializadas. Instalação de pacotes, diagnóstico, templates e manipulação de estado não devem ser duplicados no parser da CLI.

~~~mermaid
flowchart TD
    U[Usuário] --> L[Launcher devkit.cmd / devkit.ps1 / devkit.sh]
    L --> C[CLI tools/devkit.ps1 ou tools/devkit.sh]
    C --> S[Setup]
    C --> D[Dev Doctor]
    C --> T[Stacks]
    C --> P[Project Templates]
    C --> R[Runtime Adapters]
    C --> E[Environment tools]
    C --> I[Info / Config]
    S --> M[modules/catalog.json]
    T --> M
    T --> SC[stacks/*.json]
    P --> TC[templates/catalog.json]
    R --> VC[versions/*.json]
    S --> ST[.super-dev-kit/manifest.json]
    T --> ST
    R --> ST
    E --> ST
~~~

## Camadas

### 1. Launchers

Arquivos da raiz:

~~~text
devkit.cmd
devkit.ps1
devkit.sh
~~~

Responsabilidade: encontrar a implementação real e repassar argumentos.

Eles não devem conter regras de negócio.

### 2. CLI / Orquestração

~~~text
tools/devkit.ps1
tools/devkit.sh
~~~

Responsabilidades:

- reconhecer comandos;
- validar argumentos;
- manter paridade entre Windows e Linux;
- preservar códigos de saída;
- delegar para scripts internos;
- aplicar o envelope JSON público.

Não é responsabilidade desta camada instalar Node, Docker, extensões ou alterar o manifesto diretamente, exceto em caminhos públicos explicitamente tratados pela CLI.

### 3. Ferramentas especializadas

Exemplos:

~~~text
tools/install-stack.*
tools/create-project.*
tools/runtime-manager.*
tools/export-environment.*
tools/import-environment.*
tools/compare-environment.*
tools/cleanup.*
tools/devkit-info.*
tools/devkit-config.*
~~~

Cada ferramenta deve fazer uma coisa principal e ter comportamento previsível quando chamada diretamente.

### 4. Catálogos declarativos

~~~text
modules/catalog.json
stacks/*.json
templates/catalog.json
versions/catalog.json
versions/managers.json
versions/presets.json
~~~

Preferimos dados declarativos a duplicar listas dentro de vários scripts.

### 5. Estado local

~~~text
.super-dev-kit/
├── manifest.json
└── logs/
    └── events.jsonl
~~~

O manifesto registra o que foi observado ou gerenciado pelo kit.

Ele é local, ignorado pelo Git e não deve armazenar segredos.

### 6. Ambiente reproduzível

~~~mermaid
flowchart LR
    A[Máquina A] --> M[Manifesto]
    M --> E[devkit export]
    E --> L[devkit.lock.json]
    L --> I[devkit import --dry-run]
    I --> B[Máquina B]
    B --> C[devkit compare]
    C --> D[devkit doctor]
~~~

O lock file expressa intenção portável. O manifesto expressa estado local.

## Fluxo de um comando

Exemplo:

~~~text
devkit stack react --dry-run
~~~

Fluxo:

1. launcher recebe argumentos;
2. `tools/devkit.*` reconhece `stack`;
3. parser valida `react` e `--dry-run`;
4. CLI delega para `tools/install-stack.*`;
5. instalador lê `stacks/react.json`;
6. dependências são resolvidas via `modules/catalog.json`;
7. execução real ou dry-run ocorre;
8. quando aplicável, manifesto é atualizado;
9. código de saída volta pela CLI.

## Contrato de saída

Os códigos públicos da linha v1 são:

| Código | Significado |
| ---: | --- |
| 0 | sucesso |
| 1 | falha operacional |
| 2 | drift ou política não atendida |
| 64 | uso inválido |
| 69 | dependência/recurso indisponível |
| 70 | erro interno |

Uma ferramenta interna pode ter detalhes próprios, mas a CLI deve evitar transformar uso inválido em sucesso silencioso.

## JSON

A opção global `--json` usa envelope schema v1.

Scripts legados ainda podem produzir texto. Nesses casos, a CLI encapsula a saída em `output` para preservar compatibilidade sem uma reescrita total.

## Segurança

Regras importantes:

- não usar `eval` com entrada do usuário;
- não armazenar tokens/senhas no manifesto;
- não desabilitar TLS para contornar certificados;
- cleanup destrutivo exige ação explícita;
- sobrescrita de projeto exige `--force`;
- version managers não são baixados silenciosamente;
- comandos de diagnóstico devem ser somente leitura sempre que possível.

## Como adicionar comportamento à CLI

Antes de editar `tools/devkit.*`:

1. verifique se já existe uma ferramenta especializada;
2. implemente a lógica nela;
3. mantenha a CLI apenas como parser/delegador;
4. adicione o comando ao `cli/commands.json`;
5. documente em `docs/CLI.md`;
6. adicione testes Windows e Linux;
7. preserve os códigos de saída.

## Debug mental

Ao investigar um bug, identifique primeiro a camada:

~~~text
argumento não reconhecido
  -> CLI

stack errada
  -> stacks/ + modules/

projeto gerado incorretamente
  -> templates/ + create-project

runtime
  -> versions/ + runtime-manager

estado/cleanup
  -> state + manifest

rede/Docker
  -> bootstrap + Dev Doctor
~~~

Isso reduz correções no lugar errado e evita duplicação de lógica.

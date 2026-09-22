# Arquitetura do Super Dev Kit

O Super Dev Kit é organizado como uma camada de **orquestração** sobre scripts pequenos e especializados.

A CLI **devkit** não contém toda a lógica do projeto. Ela traduz comandos amigáveis e delega para os componentes já testados.

~~~text
Usuário
  │
  ├─ devkit.cmd / devkit.ps1 / devkit.sh
  │
  ▼
CLI unificada
  │
  ├─ setup
  ├─ doctor
  ├─ stack
  ├─ project
  ├─ runtime
  ├─ state
  ├─ export / import / compare
  └─ backup / inventory / cleanup / update
  │
  ▼
Scripts especializados
  │
  ├─ windows/
  ├─ linux/
  ├─ diagnostics/
  ├─ certificates/
  └─ tools/
  │
  ▼
Catálogos declarativos
  │
  ├─ modules/catalog.json
  ├─ stacks/*.json
  ├─ templates/catalog.json
  └─ versions/*.json
  │
  ▼
Estado local
  ├─ .super-dev-kit/manifest.json
  ├─ .super-dev-kit/devkit.lock.json
  └─ logs e backups locais
~~~

## Princípios

### CLI fina

A CLI deve orquestrar, não duplicar regras. Se uma stack já é instalada por tools/install-stack, o comando devkit stack chama esse componente.

### Núcleo declarativo

Módulos, stacks, templates e políticas de runtime usam JSON sempre que possível. Isso reduz divergências entre Windows e Linux.

### Compatibilidade multiplataforma

Existem caminhos equivalentes para CMD, Windows PowerShell 5.1, PowerShell 7 e Bash em Ubuntu/Linux. Wrappers CMD chamam PowerShell para evitar uma terceira implementação de regras complexas.

### Estado local

O arquivo .super-dev-kit/manifest.json descreve o que o kit observou e instalou nesta máquina. Ele permite detectar drift, fazer cleanup seguro, exportar um ambiente e diferenciar itens preexistentes de itens gerenciados pelo kit.

### Reprodutibilidade

O lock file representa a **intenção portátil** do ambiente. Stacks e módulos são priorizados em vez de copiar cegamente pacotes específicos de uma plataforma.

### Segurança por padrão

O projeto não deve desabilitar TLS, armazenar tokens ou senhas, remover pacotes preexistentes no cleanup, executar instaladores remotos de version managers sem ação explícita ou sobrescrever projetos silenciosamente.

## Fluxo de instalação

~~~text
devkit setup fullstack
        │
        ▼
CLI detecta plataforma
        │
        ├─ Windows -> windows/setup-windows.ps1
        │
        └─ Linux   -> linux/bootstrap-vm-ubuntu.sh
        │
        ▼
Instala dependências
        │
        ▼
Atualiza manifesto local
        │
        ▼
devkit doctor
~~~

## Fluxo de stack

~~~text
devkit stack react
      │
      ▼
stacks/react.json
      │
      ▼
dependências de módulos
      │
      ▼
modules/catalog.json
      │
      ▼
instalação por plataforma
~~~

## Fluxo de projeto

~~~text
devkit project react-vite meu-app
      │
      ▼
templates/catalog.json
      │
      ▼
templates/react-vite/
      │
      ▼
render de placeholders
      │
      ▼
meu-app/
~~~

## Fluxo reproduzível

~~~text
Máquina A
  ├─ devkit setup / stack
  ├─ devkit doctor
  └─ devkit export
          │
          ▼
  devkit.lock.json
          │
          ▼
Máquina B
  ├─ devkit import --dry-run
  ├─ devkit import
  ├─ devkit compare
  └─ devkit doctor
~~~

## Diretórios principais

| Diretório | Responsabilidade |
| --- | --- |
| cli/ | contrato público da CLI |
| windows/ | setup específico do Windows |
| linux/ | bootstrap Ubuntu/Linux |
| diagnostics/ | Dev Doctor |
| tools/ | componentes reutilizáveis |
| modules/ | catálogo de módulos |
| stacks/ | composição de módulos |
| templates/ | projetos geráveis |
| versions/ | constraints e version managers |
| certificates/ | suporte opcional a CA corporativa |
| examples/ | exemplos Docker |
| docs/ | documentação pública |

## Como evoluir sem duplicar lógica

Ao adicionar um recurso novo:

1. defina qual componente é dono da regra;
2. implemente a regra uma vez;
3. exponha wrappers equivalentes;
4. faça a CLI delegar para esse componente;
5. adicione dry-run quando houver alteração da máquina;
6. registre estado quando fizer sentido;
7. adicione testes Windows e Linux;
8. documente o comportamento público.

# Changelog

Todas as mudanças relevantes deste projeto serão documentadas aqui.

## 0.9.0 - 2026-09-22

### Public readiness

- README reorganizado para onboarding rápido;
- arquitetura pública documentada;
- FAQ, troubleshooting e matriz de suporte;
- exemplos de automação JSON;
- CONTRIBUTING ampliado;
- Código de Conduta;
- templates de bug, feature request e pull request;
- guias para adicionar stacks, templates e adapters;
- validador de UTF-8 e links locais;
- workflow dedicado de public readiness;
- smoke test PowerShell 7;
- onboarding descartável em Ubuntu 24.04;
- release notes e materiais de divulgação;
- checklist seguro para capturas reais da CLI.

### Qualidade

A v0.9 prioriza apresentação, documentação, contribuição e confiabilidade antes da v1.0. Não foram introduzidas grandes mudanças de arquitetura ou instalação.


## 0.8.0 - 2026-09-22

### Adicionado

- CLI unificada `devkit` para CMD, PowerShell e Bash;
- launchers `devkit.cmd`, `devkit.ps1` e `devkit.sh`;
- comandos `setup`, `doctor`, `stack`, `project`, `runtime`, `state`, `export`, `import`, `compare`, `backup`, `inventory`, `cleanup` e `update`;
- instalação opcional de shim global com `devkit cli install`;
- remoção segura do shim com `devkit cli uninstall`;
- ajuda consistente por comando;
- códigos de saída documentados;
- opção global `--json` para automações;
- contrato de comandos em `cli/commands.json`;
- testes da CLI no Windows, Linux e CMD;
- compatibilidade preservada com todos os scripts e wrappers anteriores.

### Arquitetura

A CLI atua como camada de orquestração e delega para scripts já existentes. Regras de instalação, diagnóstico, stacks, templates e ambiente reproduzível não foram duplicadas.

### Automação

A saída JSON usa um envelope estável com `command`, `success`, `exit_code`, `timestamp`, dados estruturados quando disponíveis e saída textual dos scripts legados quando necessário.

### Segurança

- o instalador global cria apenas um shim para o clone atual;
- uninstall verifica se o shim pertence ao Super Dev Kit antes de removê-lo;
- cleanup, certificados, version managers e demais proteções das versões anteriores permanecem inalterados.


## 0.7.0 - 2026-09-22

### Adicionado

- Project Wizard para CMD, PowerShell e Bash;
- gerador local de projetos com dry-run e proteção contra sobrescrita;
- templates React + Vite, Node + NestJS, .NET Web API, Python/FastAPI e Docker Compose;
- geração opcional de Dev Containers;
- metadados locais em `.devkit-project.json`;
- instalação opcional de dependências com retry controlado e uso dos caches nativos dos gerenciadores;
- adapters opcionais para fnm, nvm, pyenv, dotnet-install, SDKMAN e phpenv;
- fallback nativo quando nenhum version manager compatível está disponível;
- pinning explícito quando o manager escolhido oferece esse recurso;
- documentação dedicada para templates e version managers;
- smoke tests de geração de projetos em Windows e Linux.

### Segurança

- version managers não são baixados nem executados automaticamente;
- argumentos de versão passam por validação;
- nenhum adapter usa eval;
- geração de projeto recusa sobrescrever diretórios não vazios sem opção explícita;
- instalação de dependências continua opt-in.

### Corrigido

- opção DevOps no seletor de perfil do menu PowerShell voltou a responder à opção 6.


## 0.6.0 - 2026-09-22

### Adicionado

- manifesto schema v2 com stacks, módulos e runtimes;
- migração automática de manifestos schema v1;
- constraints de versão para Node.js, Python, .NET, Java e PHP;
- presets de compatibilidade `portable` e `modern`;
- export de ambiente para `devkit.lock.json`;
- import de ambiente com dry-run;
- reprodução baseada prioritariamente em stacks e módulos;
- comparação entre lock file e máquina real;
- detecção de drift de pacotes, extensões e runtimes;
- wrappers CMD para export, import, compare e runtime check;
- submenu de ambientes reproduzíveis;
- testes de CI para schema v2, lock files e novos fluxos.

### Reprodutibilidade

A v0.6 trabalha com constraints portáveis de runtime em vez de presumir que winget e apt possuem exatamente os mesmos patch versions. O resultado instalado é validado depois da instalação.

### Segurança

Lock files não exportam senhas, tokens, chaves privadas ou conteúdo de certificados.


## 0.5.0 - 2026-09-22

### Adicionado

- arquitetura modular centralizada em `modules/catalog.json`;
- catálogo de stacks reutilizáveis em `stacks/`;
- Stack Wizard para CMD, PowerShell e Bash;
- presets React, Node/NestJS, Full Stack React + Node, Python, .NET, Java, PHP, Data/SQL e DevOps;
- resolução automática de dependências entre módulos;
- instalação direta de stacks com dry-run;
- Dev Doctor v2 com score, categorias, sugestões e detecção de drift;
- documentação dedicada para módulos, stacks e Dev Doctor;
- validação CI dos manifests JSON e dry-runs de stacks;
- suporte a extensões VS Code adicionais por stack.

### Developer Experience

- o menu principal prioriza o Stack Wizard;
- stacks reutilizam os instaladores e o manifesto existentes;
- módulos removem duplicação de listas de dependências;
- CMD, PowerShell e Bash continuam suportados como caminhos de primeira classe.


## 0.4.0 - 2026-09-22

### Adicionado

- manifesto local por máquina em `.super-dev-kit/manifest.json`;
- registro de pacotes preexistentes versus instalados pelo Super Dev Kit;
- registro de extensões VS Code e recursos habilitados pelo kit;
- logs estruturados em JSON Lines em `.super-dev-kit/logs/events.jsonl`;
- visualizador de estado local para CMD, PowerShell e Bash;
- cleanup baseado no manifesto, preservando itens preexistentes;
- backup e restore de configurações do VS Code;
- backup e restore seguro de configurações selecionadas do Git;
- pacotes e extensões customizados via configuração declarativa;
- suporte a variáveis de proxy HTTP/HTTPS/NO_PROXY na execução declarativa;
- testes automatizados do manifesto e cleanup.

### Segurança

- `.super-dev-kit/` é ignorado pelo Git;
- cleanup remove apenas itens marcados como instalados pelo kit;
- ferramentas core e Docker continuam protegidos por padrão;
- restore do VS Code cria backup de segurança antes de sobrescrever arquivos;
- backup do Git exporta apenas chaves selecionadas e não inclui credenciais.


## 0.3.1 - 2026-09-22

### Adicionado

- launcher principal `setup.cmd`;
- wrappers CMD para instalador, Dev Doctor, configuração JSON, VS Code, inventário, update e cleanup;
- testes automatizados dos wrappers CMD no GitHub Actions;
- documentação equivalente para CMD e PowerShell.

### Compatibilidade

- Windows agora possui caminhos documentados e testados para **CMD e PowerShell**;
- os wrappers CMD reutilizam a mesma lógica PowerShell para evitar divergência entre implementações.

## 0.3.0 - 2026-09-22

### Adicionado

- dry-run para o instalador Windows;
- dry-run para o bootstrap Ubuntu;
- configuração declarativa em JSON;
- runners de configuração para Windows e Linux;
- instalação de extensões do VS Code por perfil;
- auto-update seguro com `git pull --ff-only`;
- inventário local do ambiente;
- cleanup/uninstall controlado em modo preview por padrão;
- pasta `reports/` ignorada pelo Git;
- central de operações nos menus Windows e Linux;
- documentação completa de automação avançada;
- suporte a Git name/e-mail no runner declarativo Linux;
- smoke tests em runners descartáveis.

### Segurança

- cleanup exige confirmação explícita antes de remover pacotes;
- Docker não é removido pelo cleanup sem opção específica;
- update é bloqueado quando há alterações locais não commitadas;
- configurações locais e relatórios ficam fora do versionamento.

## 0.2.0 - 2026-09-21

### Adicionado

- perfis Essential, Frontend, Backend, Full Stack, Data/SQL e DevOps;
- menus expandidos para Windows e Linux;
- exportador de certificado CA confiável no Windows;
- importador de certificado CA no Linux;
- busca automática de certificados em Downloads, /media e /mnt;
- pasta local protegida para certificados;
- Quick Start passo a passo;
- documentação dos perfis;
- exemplos Docker para Nginx, MySQL e PostgreSQL;
- Dev Doctor ampliado;
- diagnóstico de Docker Compose, grupos, SSH, TLS e VirtualBox;
- reparo preventivo de pacotes pendentes no bootstrap Ubuntu.

### Alterado

- certificado corporativo passou a ser explicitamente opcional;
- setup Ubuntu ganhou seleção de perfil;
- setup Windows ganhou instalação por perfil;
- fluxo de Docker Compose evita conflito entre implementações concorrentes;
- workflow de lint cobre os novos scripts.

## 0.1.0 - 2026-09-21

### Adicionado

- menu principal `setup.ps1` para Windows;
- menu principal `setup.sh` para Ubuntu/Linux;
- bootstrap para Windows com winget;
- instalação de Git, Node.js LTS, VS Code, PowerShell, Terminal e GitHub CLI;
- opções para WSL, Docker Desktop e Postman;
- bootstrap de VM Ubuntu;
- Docker, Docker Compose e SSH no Ubuntu;
- suporte opcional a certificado CA corporativo;
- detecção de VirtualBox e Guest Utilities;
- Dev Doctor para diagnóstico de Windows e Linux;
- documentação de SSH, certificados e problemas `x509`;
- GitHub Actions para lint;
- templates de issue e pull request;
- roadmap público do projeto.

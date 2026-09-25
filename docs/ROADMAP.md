# Roadmap

O Super Dev Kit evolui em versões pequenas para manter a instalação previsível, segura e fácil de testar.

## v0.1 — Base

- [x] Setup Windows com winget
- [x] Setup Ubuntu / VirtualBox
- [x] Git e Node.js
- [x] Docker e Docker Compose
- [x] SSH e utilitários de rede
- [x] Dev Doctor
- [x] GitHub Actions
- [x] Templates de Issue e Pull Request

## v0.2 — Perfis e experiência

- [x] Essential, Frontend, Backend, Full Stack, Data / SQL e DevOps
- [x] Menus interativos Windows e Linux
- [x] Exemplos Docker
- [x] Certificados corporativos opcionais e seguros

## v0.3 — Automação avançada

- [x] Dry-run
- [x] Configuração declarativa em JSON
- [x] Extensões VS Code por perfil
- [x] Auto-update seguro
- [x] Inventário do ambiente
- [x] CMD + PowerShell + Bash
- [x] Smoke tests multiplataforma

## v0.4 — Estado e reprodutibilidade

- [x] Manifesto por máquina
- [x] Registro do que foi instalado pelo kit
- [x] Registro de itens preexistentes
- [x] Cleanup baseado em manifesto
- [x] Backup/restauração do VS Code
- [x] Backup/restauração segura do Git
- [x] Pacotes e extensões customizados
- [x] Variáveis de proxy
- [x] Logs estruturados
- [x] Estado local protegido do Git

## v0.5 — Developer Experience e módulos

- [x] Arquitetura modular
- [x] Catálogo de stacks
- [x] React, Node/NestJS, Full Stack, .NET, Python, Java, PHP, Data/SQL e DevOps
- [x] Stack Wizard
- [x] Dev Doctor v2 com score
- [x] Detecção de drift
- [x] Presets reutilizáveis
- [x] CI validando stacks e módulos

## v0.6 — Versões e ambientes reproduzíveis

- [x] Manifesto schema v2
- [x] Registro de stacks e módulos
- [x] Registro de runtimes
- [x] Constraints selecionáveis de runtime
- [x] Node.js, Python, .NET, Java e PHP
- [x] Presets de compatibilidade
- [x] Lock file portável
- [x] Export de ambiente
- [x] Import de ambiente
- [x] Dry-run de importação
- [x] Comparação lock x máquina
- [x] Drift de pacotes/extensões/runtimes
- [x] CMD + PowerShell + Bash
- [x] CI para os fluxos de reprodutibilidade

## v0.7 — Templates e version managers

- [x] adapters opcionais para version managers
- [x] pinning mais forte de runtimes quando suportado
- [x] fallback nativo seguro
- [x] React/Vite
- [x] Node/NestJS
- [x] .NET Web API
- [x] Python API
- [x] Docker Compose
- [x] Dev Containers
- [x] Project Wizard
- [x] dry-run de geração
- [x] proteção contra sobrescrita
- [x] retry controlado de dependências
- [x] reutilização dos caches nativos dos package managers
- [x] smoke tests de templates em Windows e Linux

## v0.8 — CLI unificada

- [x] `devkit setup`
- [x] `devkit doctor`
- [x] `devkit stack`
- [x] `devkit project`
- [x] `devkit runtime`
- [x] `devkit state`
- [x] `devkit export`
- [x] `devkit import`
- [x] `devkit compare`
- [x] `devkit backup`
- [x] `devkit inventory`
- [x] `devkit cleanup`
- [x] `devkit update`
- [x] help consistente
- [x] códigos de saída documentados
- [x] dry-run padronizado por subcomando
- [x] saída JSON para automações
- [x] shim global opcional
- [x] wrappers legados preservados
- [x] smoke tests via CMD, PowerShell e Bash

## v0.9 — Preparação pública

- [x] README reorganizado para novos usuários
- [x] página de arquitetura
- [x] FAQ
- [x] troubleshooting consolidado
- [x] matriz de suporte
- [x] exemplos de saída JSON
- [x] CONTRIBUTING revisado
- [x] CODE_OF_CONDUCT
- [x] templates públicos de issue e pull request
- [x] guias para stacks, templates e adapters
- [x] validação de links locais e UTF-8
- [x] smoke test PowerShell 7
- [x] onboarding descartável Ubuntu 24.04
- [x] release notes públicas
- [x] descrição curta do projeto
- [x] drafts LinkedIn e Dev.to/Hashnode
- [x] roteiro de demonstração
- [x] checklist seguro para mídia
- [x] capturas reais da CLI adicionadas ao README
- [x] GIF/vídeo curto capturado de execução real
- [ ] labels customizadas de área aplicadas no GitHub
- [x] good first issues publicados

## v1.0 — Estável

- [x] versão 1.0.0 preparada
- [x] matriz oficial de compatibilidade
- [x] Semantic Versioning
- [x] política de breaking changes
- [x] contratos públicos da CLI documentados
- [x] códigos de saída v1 documentados
- [x] schema JSON v1 documentado
- [x] manifesto schema v2 documentado
- [x] processo de release documentado
- [x] threat model
- [x] SECURITY revisado
- [x] README final
- [x] Manual do Usuário
- [x] Quick Start v1
- [x] release notes v1.0.0
- [x] tag Git v1.0.0
- [x] GitHub Release v1.0.0
- [x] screenshots reais da CLI
- [x] demo curta real

## v1.1 — Developer Experience e confiabilidade

- [x] roadmap público da v1.1
- [x] padrão de comentários
- [x] documentação de internals
- [x] `devkit info`
- [x] `devkit config path|show|validate`
- [x] help ampliado para recursos existentes
- [ ] comentários aprofundados nos scripts críticos
- [x] Dev Doctor v3
- [ ] logs por sessão
- [ ] `--verbose` e `--debug`
- [ ] schemas formais
- [ ] testes unitários Pester/Bash
- [ ] cookbook de cenários reais
- [ ] documentação internacional ampliada
- [ ] revisão do catálogo de runtimes
- [ ] release v1.1.0

A v1.1 melhora recursos existentes antes de ampliar o catálogo de tecnologias.

## Futuro

- [ ] macOS
- [ ] Fedora
- [ ] Debian dedicado
- [ ] plugins/extensões do próprio Super Dev Kit

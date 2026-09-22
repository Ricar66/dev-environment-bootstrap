# 🚀 Super Dev Kit

**Uma CLI open source para preparar, validar e reproduzir ambientes de desenvolvimento no Windows e Ubuntu/Linux.**

[![Validate Super Dev Kit](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/lint.yml/badge.svg)](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/lint.yml)
[![Public Readiness](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/public-readiness.yml/badge.svg)](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/public-readiness.yml)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2F24.04-orange)

O **Super Dev Kit** reduz o trabalho repetitivo de configurar uma máquina de desenvolvimento. Em vez de instalar e validar manualmente Git, Node.js, Python, Docker, SSH, VS Code, ferramentas SQL e utilitários em cada notebook, VM ou laboratório, você usa uma única interface para planejar, executar e diagnosticar o ambiente.

A ideia central é:

> **dry-run primeiro, segurança por padrão e uma experiência consistente entre Windows e Linux.**

## 📖 Para quem está começando

**Idioma do Quick Start:** [Português](docs/QUICKSTART.md) · [English](docs/QUICKSTART.en.md)

Você não precisa ler o repositório inteiro.

Use esta ordem:

1. [Quick Start](docs/QUICKSTART.md) — instalação rápida;
2. [Manual do Usuário](docs/USER-MANUAL.md) — passo a passo completo;
3. [Troubleshooting](docs/TROUBLESHOOTING.md) — resolução de problemas;
4. [FAQ](docs/FAQ.md) — dúvidas frequentes.

## ⚡ Instalação rápida

Clone:

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

### Windows — CMD

Veja o plano:

~~~cmd
devkit.cmd setup fullstack --dry-run
~~~

Instale:

~~~cmd
devkit.cmd setup fullstack
devkit.cmd doctor
~~~

### Windows — PowerShell

~~~powershell
.\devkit.ps1 setup fullstack --dry-run
.\devkit.ps1 setup fullstack
.\devkit.ps1 doctor
~~~

### Ubuntu/Linux

~~~bash
bash devkit.sh setup fullstack --dry-run
bash devkit.sh setup fullstack
bash devkit.sh doctor
~~~

## ⌨️ CLI única

Depois de validar o clone, você pode instalar o comando global:

Windows:

~~~cmd
devkit.cmd cli install
~~~

Linux:

~~~bash
bash devkit.sh cli install
~~~

Abra um novo terminal:

~~~text
devkit version
devkit help
~~~

A partir daí, a experiência principal é:

~~~text
devkit setup fullstack
devkit doctor
devkit stack react
devkit project react-vite meu-app
devkit runtime node 22 --manager fnm
devkit state
devkit export
devkit import --dry-run
devkit compare
devkit backup vscode
devkit inventory
devkit cleanup
devkit update
~~~

## ✨ Principais recursos

### Setup por perfil

~~~text
devkit setup essential
devkit setup frontend
devkit setup backend
devkit setup fullstack
devkit setup datasql
devkit setup devops
~~~

Perfis permitem preparar apenas o necessário para cada tipo de uso.

### Dry-run

Antes de alterar a máquina:

~~~text
devkit setup fullstack --dry-run
devkit stack react --dry-run
devkit project react-vite meu-app --dry-run
~~~

### Dev Doctor

~~~text
devkit doctor
~~~

Verifica saúde do ambiente, Docker, rede, runtimes, manifesto e drift.

### Stacks

~~~text
devkit stack react
devkit stack node-nest
devkit stack fullstack-react-node
~~~

Stacks combinam módulos reutilizáveis sem duplicar regras de instalação.

### Templates de projeto

~~~text
devkit project list
devkit project react-vite meu-app
devkit project python-api minha-api
~~~

Templates atuais incluem:

- React + Vite;
- Node + NestJS;
- .NET Web API;
- Python + FastAPI;
- Docker Compose.

### Dev Containers

~~~text
devkit project react-vite meu-app --with-devcontainer
~~~

### Version managers

~~~text
devkit runtime list
devkit runtime node 22 --manager fnm --dry-run
~~~

O Super Dev Kit usa adapters para version managers já existentes e não baixa managers automaticamente.

### Estado local

~~~text
devkit state
~~~

O estado fica em:

~~~text
.super-dev-kit/manifest.json
~~~

Ele ajuda o projeto a distinguir o que já existia do que foi instalado pelo kit.

### Ambientes reproduzíveis

Na máquina original:

~~~text
devkit export
~~~

Na nova máquina:

~~~text
devkit import --dry-run
devkit import
devkit compare
devkit doctor
~~~

### Automação JSON

~~~text
devkit version --json
devkit state --json
devkit stack react --dry-run --json
~~~

Útil para CI, scripts e integrações.

## 🧩 Perfis disponíveis

| Perfil | Indicado para | Base principal |
| --- | --- | --- |
| Essential | ambiente mínimo | Git, terminal e utilitários |
| Frontend | desenvolvimento web | Node.js, npm, VS Code |
| Backend | APIs e serviços | Node.js, Python, Docker |
| Full Stack | aplicações completas | frontend + backend + containers |
| Data / SQL | estudos e dados | Python, SQL e clientes |
| DevOps | infraestrutura | Docker, SSH e utilitários |

Detalhes: [Perfis](docs/PROFILES.md).

## 🖥️ Plataformas

| Plataforma | Status v1 |
| --- | --- |
| Windows 11 | ✅ Suportado |
| Windows 10 | ✅ Suportado com winget |
| CMD | ✅ Suportado |
| Windows PowerShell 5.1 | ✅ Suportado |
| PowerShell 7 | ✅ Suportado |
| Ubuntu 24.04 | ✅ Suportado |
| Ubuntu 22.04 | 🟡 Compatível |
| VirtualBox + Ubuntu | ✅ Suportado |
| WSL 2 | 🟡 Parcial |
| macOS | ❌ Fora de suporte |
| Fedora | ❌ Fora de suporte |

Veja [Matriz de suporte](docs/SUPPORT-MATRIX.md).

## 🔐 Certificados corporativos

A maioria das máquinas **não precisa** de certificado adicional.

Se isto funcionar:

~~~text
docker run --rm hello-world
~~~

não faça nenhuma configuração extra.

Somente em redes com inspeção HTTPS você pode encontrar:

~~~text
x509: certificate signed by unknown authority
~~~

Nesse caso, siga [Certificados corporativos](docs/CERTIFICADOS-CORPORATIVOS.md).

O projeto:

- não distribui certificados internos;
- não armazena certificados privados;
- não recomenda desativar TLS;
- mostra informações do certificado antes da importação.

## 🐳 Docker

O kit consegue preparar Docker e Docker Compose e possui exemplos em:

~~~text
examples/
├── nginx/
├── mysql/
└── postgres/
~~~

Teste básico:

~~~text
docker version
docker compose version
docker run --rm hello-world
~~~

## 🔁 Reprodutibilidade e drift

O Super Dev Kit trabalha com três conceitos:

**Manifesto local:** o que o kit observou/gerenciou na máquina.

**Lock file:** intenção portátil do ambiente.

**Drift:** diferença entre o estado esperado e o estado real.

Fluxo:

~~~text
devkit setup
devkit doctor
devkit export
        ↓
devkit.lock.json
        ↓
devkit import --dry-run
devkit import
devkit compare
devkit doctor
~~~

Veja [Ambientes reproduzíveis](docs/REPRODUCIBILITY.md).

## 🧹 Cleanup seguro

Preview:

~~~text
devkit cleanup
~~~

Aplicar:

~~~text
devkit cleanup --apply
~~~

O cleanup usa o manifesto para preservar, sempre que possível, itens que já existiam antes do kit.

## 🔄 Atualização

~~~text
devkit update
~~~

ou:

~~~text
git pull
~~~

O updater bloqueia a atualização quando existem alterações locais não salvas.

## 🏛️ Arquitetura

A CLI é fina e delega para componentes especializados.

~~~text
Usuário
  ↓
devkit
  ↓
CLI unificada
  ↓
scripts Windows / Linux / diagnostics / tools
  ↓
módulos + stacks + templates + versões
  ↓
manifesto / lock file
~~~

Isso reduz duplicação entre CMD, PowerShell e Bash.

Veja [Arquitetura](docs/ARCHITECTURE.md).

## 🛡️ Segurança

Princípios da v1:

- dry-run antes de mudanças importantes;
- TLS não é desabilitado para esconder erros;
- certificados corporativos são opcionais;
- segredos não devem entrar no repositório;
- cleanup é baseado em manifesto;
- sobrescrita de projeto exige ação explícita;
- version managers não são baixados automaticamente;
- update usa fluxo Git previsível;
- Docker no grupo docker é tratado como acesso privilegiado.

Leia:

- [Política de Segurança](SECURITY.md)
- [Threat Model](docs/THREAT-MODEL.md)

## 🧪 Qualidade

A validação automatizada cobre:

- Bash + ShellCheck;
- Windows PowerShell 5.1;
- PowerShell 7;
- CMD;
- Ubuntu;
- JSON;
- templates;
- CLI;
- estado e lock file;
- UTF-8;
- links locais;
- onboarding Ubuntu 24.04 descartável.

## 📚 Documentação

### Usuário

- [Manual do Usuário](docs/USER-MANUAL.md)
- [Quick Start](docs/QUICKSTART.md)
- [CLI](docs/CLI.md)
- [FAQ](docs/FAQ.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Matriz de suporte](docs/SUPPORT-MATRIX.md)
- [Perfis](docs/PROFILES.md)
- [Stacks](docs/STACKS.md)
- [Project Templates](docs/PROJECT-TEMPLATES.md)
- [Version Manager Adapters](docs/VERSION-MANAGERS.md)
- [Dev Doctor](docs/DEV-DOCTOR.md)
- [Ambientes reproduzíveis](docs/REPRODUCIBILITY.md)
- [Automação JSON](docs/JSON-AUTOMATION.md)
- [Certificados corporativos](docs/CERTIFICADOS-CORPORATIVOS.md)

### Projeto e contribuição

- [Arquitetura](docs/ARCHITECTURE.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [Código de Conduta](CODE_OF_CONDUCT.md)
- [Versionamento](docs/VERSIONING.md)
- [Processo de Release](docs/RELEASE-PROCESS.md)
- [Threat Model](docs/THREAT-MODEL.md)
- [Como adicionar stacks](docs/ADDING-STACKS.md)
- [Como adicionar templates](docs/ADDING-TEMPLATES.md)
- [Como adicionar adapters](docs/ADDING-ADAPTERS.md)
- [Roadmap](docs/ROADMAP.md)

## 🤝 Contribuições

Issues e pull requests são bem-vindos.

Há tarefas marcadas como **good first issue** para quem quiser contribuir pela primeira vez.

Antes de abrir um PR, leia [CONTRIBUTING.md](CONTRIBUTING.md).

## 🆘 Reportar um problema

Antes de abrir uma issue:

~~~text
devkit version
devkit doctor
devkit state
~~~

Nunca publique:

- tokens;
- senhas;
- chaves privadas;
- certificados internos;
- dados de clientes;
- informações privadas desnecessárias.

## 📦 Versão estável

**v1.0.0**

A partir da v1, o projeto segue [Semantic Versioning](docs/VERSIONING.md).

Release notes: [v1.0.0](docs/releases/v1.0.0.md).

## 📄 Licença

MIT. Consulte [LICENSE](LICENSE).

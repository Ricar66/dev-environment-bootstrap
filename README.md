# 🚀 Super Dev Kit

**Prepare, valide e reproduza ambientes de desenvolvimento no Windows e Ubuntu/Linux com uma única CLI.**

[![Validate Super Dev Kit](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/lint.yml/badge.svg)](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/lint.yml)
[![Public Readiness](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/public-readiness.yml/badge.svg)](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/public-readiness.yml)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2F24.04-orange)

O Super Dev Kit automatiza tarefas repetitivas de onboarding: Git, Node.js, Python, Docker, SSH, VS Code, clientes SQL, stacks, templates, diagnóstico e reprodução de ambientes.

A filosofia é simples: **dry-run primeiro, segurança por padrão e a mesma intenção em Windows e Linux.**

## ⚡ Comece em poucos minutos

### 1. Clone

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

### 2. Veja o plano antes de instalar

Windows — CMD:

~~~cmd
devkit.cmd setup fullstack --dry-run
~~~

Windows — PowerShell:

~~~powershell
.\devkit.ps1 setup fullstack --dry-run
~~~

Ubuntu/Linux:

~~~bash
bash devkit.sh setup fullstack --dry-run
~~~

### 3. Execute e valide

Depois de revisar o dry-run:

~~~text
devkit setup fullstack
devkit doctor
~~~

Antes de instalar o comando global, use devkit.cmd, .\devkit.ps1 ou bash devkit.sh.

Guia completo: [Quick Start](docs/QUICKSTART.md).

## ✨ O que ele faz

| Recurso | Exemplo |
| --- | --- |
| Setup por perfil | devkit setup fullstack |
| Diagnóstico | devkit doctor |
| Stacks | devkit stack react |
| Geração de projetos | devkit project react-vite meu-app |
| Version managers | devkit runtime node 22 --manager fnm |
| Estado local | devkit state |
| Export de ambiente | devkit export |
| Import reproduzível | devkit import --dry-run |
| Comparação / drift | devkit compare |
| Backup | devkit backup vscode |
| Inventário | devkit inventory |
| Cleanup controlado | devkit cleanup |
| Atualização segura | devkit update |
| Automação JSON | devkit state --json |

## 🧩 Perfis

- **Essential** — base de desenvolvimento;
- **Frontend** — Node.js e ferramentas web;
- **Backend** — Node.js, Python, Docker e APIs;
- **Full Stack** — frontend + backend + containers;
- **Data / SQL** — Python, SQL e clientes de banco;
- **DevOps** — Docker, SSH e ferramentas de infraestrutura.

Veja [Perfis](docs/PROFILES.md).

## 🧰 Stacks

Stacks combinam módulos reutilizáveis.

Exemplos:

~~~text
devkit stack react --dry-run
devkit stack node-nest --dry-run
devkit stack fullstack-react-node --dry-run
~~~

O catálogo inclui React, Node/NestJS, .NET, Python, Java, PHP, Data/SQL e DevOps.

Veja [Stacks](docs/STACKS.md) e [Arquitetura de módulos](docs/MODULES.md).

## 🏗️ Templates de projeto

~~~text
devkit project list
devkit project react-vite meu-app --dry-run
devkit project python-api minha-api
~~~

Templates atuais:

- React + Vite;
- Node + NestJS;
- .NET Web API;
- Python + FastAPI;
- Docker Compose.

Dev Containers podem ser adicionados opcionalmente.

Veja [Project Templates](docs/PROJECT-TEMPLATES.md).

## 🩺 Dev Doctor

~~~text
devkit doctor
~~~

O diagnóstico verifica itens aplicáveis, como:

- espaço em disco;
- Git, curl e ferramentas core;
- runtimes;
- Docker e Compose;
- SSH;
- DNS e HTTPS;
- manifesto local;
- drift.

Veja [Dev Doctor](docs/DEV-DOCTOR.md).

## 🔁 Ambientes reproduzíveis

Na máquina de origem:

~~~text
devkit export
~~~

Na máquina de destino:

~~~text
devkit import --dry-run
devkit import
devkit compare
~~~

O lock file representa a intenção do ambiente sem exportar senhas, tokens, chaves privadas ou conteúdo de certificados.

Veja [Ambientes reproduzíveis](docs/REPRODUCIBILITY.md).

## 🤖 Automação

A CLI possui saída JSON:

~~~text
devkit version --json
devkit state --json
devkit stack react --dry-run --json
~~~

Veja [Automação JSON](docs/JSON-AUTOMATION.md).

## 🔐 Redes corporativas e certificados

**Certificado adicional é opcional.**

Se Docker e HTTPS funcionarem, não faça nada.

Se aparecer erro como:

~~~text
x509: certificate signed by unknown authority
~~~

use o fluxo documentado de CA autorizada.

O projeto não distribui certificados internos e não recomenda desabilitar TLS.

Veja [Certificados corporativos](docs/CERTIFICADOS-CORPORATIVOS.md).

## ⌨️ Instalar o comando global

Depois de validar o clone:

Windows:

~~~text
devkit.cmd cli install
~~~

Linux:

~~~text
bash devkit.sh cli install
~~~

Abra um novo terminal:

~~~text
devkit version
~~~

O shim aponta para o clone atual. Se mover o repositório, reinstale o shim.

Veja [CLI](docs/CLI.md).

## 🖥️ Plataformas

| Plataforma | Status |
| --- | --- |
| Windows 11 | Suportado |
| Windows 10 | Suportado |
| CMD | Suportado |
| Windows PowerShell 5.1 | Suportado |
| PowerShell 7 | Suportado |
| Ubuntu 24.04 | Suportado |
| Ubuntu 22.04 | Compatível |
| VirtualBox + Ubuntu | Suportado |
| WSL 2 | Parcial |
| macOS | Ainda não suportado |

Detalhes: [Matriz de suporte](docs/SUPPORT-MATRIX.md).

## 🏛️ Arquitetura

A CLI é uma camada fina de orquestração.

~~~text
devkit
  │
  ├─ scripts Windows/Linux
  ├─ Dev Doctor
  ├─ módulos e stacks
  ├─ templates
  ├─ version managers
  └─ manifesto / lock file
~~~

As regras não são duplicadas entre CMD, PowerShell e Bash.

Veja [Arquitetura](docs/ARCHITECTURE.md).

## 🛡️ Segurança

O projeto busca:

- não desabilitar TLS;
- não versionar segredos;
- preservar software preexistente no cleanup;
- exigir ação explícita para mudanças sensíveis;
- usar dry-run sempre que possível;
- não baixar version managers automaticamente;
- manter certificados corporativos fora do Git.

Leia [SECURITY.md](SECURITY.md).

## 🧪 Qualidade

Pull requests passam por validações em runners descartáveis:

- Bash syntax + ShellCheck;
- PowerShell Script Analyzer;
- Windows PowerShell 5.1;
- PowerShell 7;
- CMD;
- Ubuntu/Linux;
- JSON;
- geração de templates;
- estado/lock file;
- UTF-8;
- links locais da documentação;
- onboarding em Ubuntu 24.04 descartável.

## 🤝 Contribuindo

Contribuições são bem-vindas.

Comece por:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [Código de Conduta](CODE_OF_CONDUCT.md)
- [Como adicionar stacks](docs/ADDING-STACKS.md)
- [Como adicionar templates](docs/ADDING-TEMPLATES.md)
- [Como adicionar adapters](docs/ADDING-ADAPTERS.md)

## 🆘 Ajuda

- [FAQ](docs/FAQ.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Quick Start](docs/QUICKSTART.md)
- [Matriz de suporte](docs/SUPPORT-MATRIX.md)

Ao reportar um bug, inclua devkit version e devkit doctor, removendo dados sensíveis.

## 📚 Documentação

- [Quick Start](docs/QUICKSTART.md)
- [CLI](docs/CLI.md)
- [Arquitetura](docs/ARCHITECTURE.md)
- [Perfis](docs/PROFILES.md)
- [Stacks](docs/STACKS.md)
- [Módulos](docs/MODULES.md)
- [Project Templates](docs/PROJECT-TEMPLATES.md)
- [Version Manager Adapters](docs/VERSION-MANAGERS.md)
- [Dev Doctor](docs/DEV-DOCTOR.md)
- [Ambientes reproduzíveis](docs/REPRODUCIBILITY.md)
- [Automação JSON](docs/JSON-AUTOMATION.md)
- [Certificados corporativos](docs/CERTIFICADOS-CORPORATIVOS.md)
- [Windows](docs/WINDOWS.md)
- [Ubuntu / VM](docs/UBUNTU-VM.md)
- [VirtualBox + SSH](docs/VIRTUALBOX-SSH.md)
- [Roadmap](docs/ROADMAP.md)

## 📦 Versão

Versão em desenvolvimento desta branch: **0.9.0**.

Veja [CHANGELOG.md](CHANGELOG.md) e as [release notes da v0.9](docs/releases/v0.9.0.md).

## 📄 Licença

MIT. Consulte [LICENSE](LICENSE).

# 🚀 Super Dev Kit

Um kit open source para preparar, validar e documentar rapidamente um ambiente de desenvolvimento no **Windows** e em **Ubuntu/VirtualBox**.

A ideia é simples: em vez de configurar Git, Node.js, Docker, SSH, VS Code, ferramentas de API, clientes SQL e utilitários manualmente em toda máquina nova, você clona um repositório, escolhe um perfil e deixa o kit fazer o trabalho repetitivo.

![Lint scripts](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/lint.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-VM-orange)

## ⚡ Comece por aqui

Guia completo: [Quick Start passo a passo](docs/QUICKSTART.md)

### Windows

Se ainda não tiver Git:

```powershell
winget install --id Git.Git -e
```

Depois:

```powershell
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

Abra o PowerShell como **Administrador**.

### Ubuntu / Linux

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
bash setup.sh
```

Usamos `bash setup.sh` para que o funcionamento não dependa da permissão executável do arquivo no clone.

## 🧩 Perfis

O menu possui perfis para diferentes tipos de ambiente:

| Perfil | Foco |
| --- | --- |
| Essential | Git, editor, terminal e utilitários |
| Frontend | Node.js, npm e ferramentas para APIs |
| Backend | Node.js, Python, Docker e APIs |
| FullStack | Frontend + Backend + containers |
| Data / SQL | Python, SQL, clientes de banco e Docker |
| DevOps | Docker, WSL/SSH e ferramentas de ambiente |

Detalhes: [Perfis de desenvolvimento](docs/PROFILES.md)

## ⚙️ Automação avançada v0.3

A v0.3 transforma o projeto em uma central de operações para o ambiente de desenvolvimento:

- dry-run antes de qualquer instalação;
- configuração declarativa em JSON;
- extensões do VS Code por perfil;
- auto-update seguro;
- inventário de ferramentas e versões;
- cleanup/uninstall controlado;
- relatórios locais ignorados pelo Git;
- smoke tests em Windows e Linux via GitHub Actions.

Exemplo de dry-run:

```bash
bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --dry-run
```

```powershell
.\windows\setup-windows.ps1 -Profile FullStack -DryRun
```

Configuração local:

```text
config/devkit.config.json
```

Ela pode definir perfil, Git, Docker/WSL, extensões e certificado opcional. Veja [Automação avançada](docs/AUTOMATION.md).

## 🪟 Windows

O instalador usa **winget** e pode configurar:

- Git
- Visual Studio Code
- PowerShell 7
- Windows Terminal
- GitHub CLI
- 7-Zip
- Node.js LTS
- Python
- Postman
- DBeaver
- Docker Desktop
- WSL

Execução direta por perfil:

```powershell
.\windows\setup-windows.ps1 -Profile Frontend
```

```powershell
.\windows\setup-windows.ps1 -Profile FullStack
```

```powershell
.\windows\setup-windows.ps1 -Profile DataSQL
```

Para instalar tudo:

```powershell
.\windows\setup-windows.ps1 -All
```

## 🐧 Ubuntu / VirtualBox

O bootstrap Linux instala a base do ambiente, Docker, Compose, SSH, ferramentas de rede e componentes adicionais conforme o perfil.

Exemplo:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack
```

Data / SQL:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile datasql
```

DevOps:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile devops
```

Quando executado dentro do VirtualBox, o script também tenta instalar Guest Utilities e configurar o grupo `vboxsf`.

## 🔐 Certificados corporativos: somente quando necessário

**Nem toda máquina precisa de certificado adicional.**

Primeiro faça a instalação normalmente e teste:

```bash
docker run --rm hello-world
```

Se funcionar, não precisa fazer mais nada.

Se aparecer erro como:

```text
x509: certificate signed by unknown authority
```

o Super Dev Kit possui um fluxo específico para redes com proxy/firewall fazendo inspeção HTTPS.

Descubra o emissor:

```bash
curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -i issuer
```

No Windows, exporte **somente o certificado público**:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor"
```

O arquivo fica localmente em:

```text
certificates\local\devkit-root-ca.cer
```

Essa pasta é ignorada pelo Git.

Na VM Linux:

```bash
sudo bash certificates/import-ca-linux.sh --auto
```

O importador encontra arquivos `.cer/.crt`, mostra Subject, Issuer, validade e fingerprint e pede confirmação antes de confiar na CA.

Veja o guia completo: [Certificados corporativos e x509](docs/CERTIFICADOS-CORPORATIVOS.md)

> O repositório não distribui certificados internos de empresas ou instituições. Ele fornece as ferramentas para que cada usuário trabalhe com a CA autorizada da própria rede.

## 🩺 Dev Doctor

O Dev Doctor ajuda a entender rapidamente se o ambiente está pronto.

Windows:

```powershell
.\diagnostics\dev-doctor.ps1
```

Linux:

```bash
bash diagnostics/dev-doctor.sh
```

Ele verifica ferramentas, Docker, SSH e conectividade HTTPS.

## 🐳 Exemplos Docker

O repositório inclui exemplos prontos:

```text
examples/
├── nginx/
├── mysql/
└── postgres/
```

Nginx:

```bash
cd examples/nginx
docker compose up -d
```

MySQL:

```bash
cd examples/mysql
cp .env.example .env
docker compose up -d
```

PostgreSQL:

```bash
cd examples/postgres
cp .env.example .env
docker compose up -d
```

Veja [examples/README.md](examples/README.md).

## 📁 Estrutura

```text
.
├── setup.ps1
├── setup.sh
├── windows/
│   └── setup-windows.ps1
├── linux/
│   └── bootstrap-vm-ubuntu.sh
├── diagnostics/
│   ├── dev-doctor.ps1
│   └── dev-doctor.sh
├── certificates/
│   ├── export-root-ca.ps1
│   ├── import-ca-linux.sh
│   └── local/
├── examples/
│   ├── nginx/
│   ├── mysql/
│   └── postgres/
├── config/
│   └── devkit.config.example.json
├── tools/
│   ├── run-config.*
│   ├── install-vscode-extensions.*
│   ├── update-devkit.*
│   ├── inventory.*
│   └── cleanup.*
├── reports/
├── docs/
│   ├── QUICKSTART.md
│   ├── PROFILES.md
│   ├── WINDOWS.md
│   ├── UBUNTU-VM.md
│   ├── VIRTUALBOX-SSH.md
│   ├── CERTIFICADOS-CORPORATIVOS.md
│   └── ROADMAP.md
├── .github/
├── CONTRIBUTING.md
├── SECURITY.md
├── CHANGELOG.md
└── LICENSE
```

## 🔄 Atualização

Depois de clonar uma vez:

```bash
git pull
```

ou no PowerShell:

```powershell
git pull
```

## Filosofia

O Super Dev Kit busca ser:

- **legível** — scripts que também servem para estudo;
- **idempotente** — repetir uma instalação não deve duplicar configuração;
- **seguro** — não desabilita TLS para esconder problemas;
- **modular** — cada pessoa escolhe o perfil que precisa;
- **diagnosticável** — erros devem apontar o próximo passo;
- **reutilizável** — útil em novas VMs, notebooks e ambientes de estudo.

## Documentação

- [Quick Start](docs/QUICKSTART.md)
- [Automação avançada v0.3](docs/AUTOMATION.md)
- [Perfis](docs/PROFILES.md)
- [Windows](docs/WINDOWS.md)
- [Ubuntu / VM](docs/UBUNTU-VM.md)
- [VirtualBox + SSH](docs/VIRTUALBOX-SSH.md)
- [Certificados corporativos](docs/CERTIFICADOS-CORPORATIVOS.md)
- [Roadmap](docs/ROADMAP.md)

## Contribuições

Issues e pull requests são bem-vindos. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Segurança

Leia [SECURITY.md](SECURITY.md) antes de compartilhar logs, certificados ou reportar uma vulnerabilidade.

## Licença

MIT. Consulte [LICENSE](LICENSE).

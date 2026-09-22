# 🚀 Super Dev Kit

Um kit open source para preparar, validar e documentar rapidamente um ambiente de desenvolvimento no **Windows** e em **Ubuntu/VirtualBox**.

A proposta é transformar horas de configuração em poucos comandos, sem esconder o que está acontecendo. O projeto foi pensado para estudantes, iniciantes e desenvolvedores que querem um ambiente reproduzível, seguro e fácil de diagnosticar.

![Lint scripts](https://github.com/Ricar66/dev-environment-bootstrap/actions/workflows/lint.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-VM-orange)

## ⚡ Modo fácil

No Windows, execute o menu principal em um PowerShell aberto como Administrador:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

No Ubuntu/Linux:

```bash
chmod +x setup.sh
./setup.sh
```

O menu permite instalar os componentes principais ou executar o **Dev Doctor**, que verifica as ferramentas e alguns problemas comuns do ambiente.

## O que este repositório configura

### Windows

O script `windows/setup-windows.ps1` usa **winget** e instala, por padrão:

- Git
- Node.js LTS
- Visual Studio Code
- PowerShell 7
- Windows Terminal
- GitHub CLI
- 7-Zip

Também existem opções para Docker Desktop, WSL, Postman e configuração inicial do Git.

### Ubuntu / VirtualBox

O script `linux/bootstrap-vm-ubuntu.sh` prepara uma VM Ubuntu com:

- Git, curl, wget, unzip e zip
- nano, vim, htop, tree e jq
- ferramentas de rede e compilação
- OpenSSH Server
- Docker e Docker Compose
- VirtualBox Guest Utilities, quando o VirtualBox é detectado
- grupos `docker` e `vboxsf`
- certificado CA corporativo opcional
- testes de HTTPS, Docker Hub, SSH e `hello-world`

## Início rápido

### Windows

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

Ou execute diretamente:

```powershell
.\windows\setup-windows.ps1 -All
```

Para configurar também a identidade do Git:

```powershell
.\windows\setup-windows.ps1 `
  -GitName "Seu Nome" `
  -GitEmail "seu-email@exemplo.com"
```

### Ubuntu

```bash
chmod +x setup.sh
./setup.sh
```

Ou diretamente:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh
```

Em uma rede corporativa que faça inspeção HTTPS:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh /caminho/certificado-raiz.cer
```

> Nunca publique no GitHub certificados privados, chaves, tokens ou arquivos internos da sua empresa/escola.

## 🩺 Dev Doctor

O projeto inclui diagnóstico rápido para verificar se ferramentas essenciais estão disponíveis e detectar alguns problemas comuns.

Windows:

```powershell
.\diagnostics\dev-doctor.ps1
```

Linux:

```bash
bash diagnostics/dev-doctor.sh
```

## Estrutura

```text
.
├── setup.ps1
├── setup.sh
├── diagnostics/
│   ├── dev-doctor.ps1
│   └── dev-doctor.sh
├── windows/
│   └── setup-windows.ps1
├── linux/
│   └── bootstrap-vm-ubuntu.sh
├── docs/
│   ├── WINDOWS.md
│   ├── UBUNTU-VM.md
│   ├── VIRTUALBOX-SSH.md
│   ├── CERTIFICADOS-CORPORATIVOS.md
│   └── ROADMAP.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── CONTRIBUTING.md
├── SECURITY.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Filosofia

Os scripts buscam ser:

- **legíveis**: comandos fáceis de estudar;
- **idempotentes**: executar novamente não deve duplicar configurações;
- **seguros**: não desabilitam validação TLS para contornar certificados;
- **modulares**: componentes opcionais são ativados por parâmetro;
- **educacionais**: a documentação explica o motivo das etapas.

## Documentação

- [Configuração do Windows](docs/WINDOWS.md)
- [VM Ubuntu](docs/UBUNTU-VM.md)
- [VirtualBox + SSH](docs/VIRTUALBOX-SSH.md)
- [Certificados corporativos e erro x509](docs/CERTIFICADOS-CORPORATIVOS.md)
- [Roadmap](docs/ROADMAP.md)

## Problemas comuns

### `docker: permission denied`

Depois de adicionar seu usuário ao grupo `docker`, faça logout/login ou:

```bash
newgrp docker
```

### `x509: certificate signed by unknown authority`

A rede pode estar usando proxy/firewall com inspeção HTTPS. Consulte [Certificados corporativos](docs/CERTIFICADOS-CORPORATIVOS.md).

### `winget` não encontrado

No Windows, instale ou atualize **App Installer** pela Microsoft Store.

## Contribuições

Issues e pull requests são bem-vindos. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Segurança

Leia [SECURITY.md](SECURITY.md) antes de reportar uma vulnerabilidade ou compartilhar logs.

## Licença

MIT. Consulte [LICENSE](LICENSE).

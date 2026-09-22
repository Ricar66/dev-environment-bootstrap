# Changelog

Todas as mudanças relevantes deste projeto serão documentadas aqui.

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

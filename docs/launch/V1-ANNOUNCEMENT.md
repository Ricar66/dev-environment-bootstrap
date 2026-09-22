# Anúncio público — Super Dev Kit v1.0.0

## Versão curta

O **Super Dev Kit v1.0.0** está pronto.

É uma CLI open source para preparar, diagnosticar e reproduzir ambientes de desenvolvimento no Windows e Ubuntu/Linux.

~~~text
devkit setup fullstack
devkit doctor
devkit stack react
devkit project react-vite meu-app
devkit export
devkit compare
~~~

A v1.0 consolida suporte a CMD, PowerShell e Bash, dry-run, Docker, stacks, templates, Dev Doctor, manifesto local, lock file reproduzível, cleanup seguro e automação JSON.

Repositório:
https://github.com/Ricar66/dev-environment-bootstrap

## LinkedIn

Depois de várias iterações, o **Super Dev Kit chegou à v1.0.0**.

O projeto nasceu de um problema bem simples: toda máquina nova de desenvolvimento exige repetir uma lista enorme de configurações.

Git. Node. Python. Docker. SSH. VS Code. Clientes SQL. Extensões. Diagnóstico. Certificados em redes corporativas.

A proposta do Super Dev Kit é colocar isso em um fluxo previsível:

~~~text
devkit setup fullstack --dry-run
devkit setup fullstack
devkit doctor
~~~

Além do setup, hoje ele também possui:

- stacks reutilizáveis;
- templates de projeto;
- Dev Containers opcionais;
- Dev Doctor;
- manifesto local;
- export/import de ambientes;
- detecção de drift;
- cleanup controlado;
- adapters de version managers;
- saída JSON para automações.

A v1.0 também formaliza o que eu considero uma parte importante de qualquer ferramenta para dev: documentação e previsibilidade.

Agora o projeto possui Manual do Usuário, matriz de suporte, arquitetura, troubleshooting, threat model, Semantic Versioning e CI para Windows, Linux, CMD, PowerShell e Bash.

O projeto é open source:

https://github.com/Ricar66/dev-environment-bootstrap

Feedback, issues e contribuições são bem-vindos.

#opensource #devtools #developerexperience #docker #linux #windows #powershell #automation

## Texto para GitHub Release

### Super Dev Kit v1.0.0

Primeira versão estável.

**Destaques:**

- CLI unificada devkit;
- Windows 10/11 e Ubuntu 24.04;
- CMD, PowerShell 5.1, PowerShell 7 e Bash;
- perfis de desenvolvimento;
- stacks;
- templates de projeto;
- Docker e Docker Compose;
- Dev Doctor;
- ambientes reproduzíveis;
- manifesto e drift;
- automação JSON;
- certificado corporativo opcional;
- Manual do Usuário completo.

Comece pelo README e pelo Manual do Usuário.

### Quick Start

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

Windows:

~~~text
devkit.cmd setup fullstack --dry-run
devkit.cmd setup fullstack
devkit.cmd doctor
~~~

Linux:

~~~text
bash devkit.sh setup fullstack --dry-run
bash devkit.sh setup fullstack
bash devkit.sh doctor
~~~

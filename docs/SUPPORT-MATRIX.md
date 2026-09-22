# Matriz de suporte — v1

Esta matriz define o suporte público da linha v1.

| Ambiente | Status | Interface | Observações |
| --- | --- | --- | --- |
| Windows 11 | Suportado | CMD / PowerShell | alvo principal Windows |
| Windows 10 | Suportado | CMD / PowerShell | requer winget/App Installer funcional |
| Windows PowerShell 5.1 | Suportado | PowerShell / CMD | compatibilidade mantida |
| PowerShell 7 | Suportado | PowerShell | smoke tests dedicados |
| Ubuntu 24.04 | Suportado | Bash | alvo Linux principal |
| Ubuntu 22.04 | Compatível | Bash | catálogos apt podem variar |
| VirtualBox + Ubuntu | Suportado | Bash | Guest Utilities quando detectáveis |
| WSL 2 | Parcial | Windows + Linux | comportamento depende da distribuição e integração Docker |
| Docker Desktop | Suportado | Windows | instalação opcional |
| Docker Engine via Ubuntu apt | Suportado | Linux | caminho oficial do bootstrap |
| macOS | Fora de suporte | — | futuro |
| Fedora | Fora de suporte | — | futuro |
| Debian dedicado | Experimental | Bash | scripts usam apt, mas alvo oficial é Ubuntu |

## Versões mínimas

### Windows

- Windows 10 ou 11;
- winget disponível para os fluxos de instalação;
- Windows PowerShell 5.1 ou PowerShell 7.

### Linux

- Ubuntu 22.04 ou superior para uso compatível;
- Ubuntu 24.04 como principal versão validada;
- Bash;
- apt.

## O que “suportado” significa

O projeto busca fornecer:

- documentação;
- dry-run;
- CI ou smoke tests equivalentes;
- troubleshooting;
- compatibilidade da CLI;
- correções para regressões reproduzíveis.

## O que não é garantido

Pacotes de terceiros podem mudar ou desaparecer dos catálogos externos.

Isso inclui winget, apt, Docker Hub, VS Code Marketplace e package managers de runtimes.

## WSL 2

WSL 2 é útil, mas não é tratado como idêntico a uma VM Ubuntu.

Alguns pontos variam:

- systemd;
- Docker Desktop integration;
- rede;
- montagem de discos;
- permissões.

Use o suporte como parcial até existir cobertura mais completa de testes.

## Redes corporativas

Inspeção HTTPS é suportada por um fluxo opcional de CA.

O projeto não distribui certificados internos e não desabilita validação TLS.

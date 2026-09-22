# Matriz de suporte

A matriz abaixo descreve o suporte pretendido pelo projeto na v0.9.

| Ambiente | Status | Interface principal | Observações |
| --- | --- | --- | --- |
| Windows 11 | Suportado | CMD / PowerShell | caminho principal no Windows |
| Windows 10 | Suportado | CMD / PowerShell | depende de winget/App Installer disponível |
| Windows PowerShell 5.1 | Suportado | .ps1 / CMD | CI valida fluxos principais |
| PowerShell 7 | Suportado | .ps1 | smoke tests dedicados |
| Ubuntu 24.04 | Suportado | Bash | alvo Linux principal |
| Ubuntu 22.04 | Compatível | Bash | pode haver diferenças de catálogo apt |
| VirtualBox + Ubuntu | Suportado | Bash | inclui Guest Utilities quando detectável |
| WSL 2 | Parcial | Windows + Linux | validar particularidades da distro |
| Docker Desktop | Suportado | Windows | instalação opcional |
| Docker Engine via Ubuntu apt | Suportado | Linux | caminho do bootstrap |
| macOS | Não suportado | — | roadmap futuro |
| Fedora | Não suportado | — | roadmap futuro |
| Debian dedicado | Experimental | Bash | alvo documentado continua sendo Ubuntu |

## O que significa “suportado”

O projeto busca manter documentação, dry-run, CI ou smoke tests equivalentes, troubleshooting e compatibilidade da CLI.

Não significa que todo pacote de terceiros esteja disponível em toda versão do sistema operacional.

## Dependências externas

Alguns resultados dependem dos catálogos de terceiros, como winget, apt, Docker Hub, VS Code Marketplace e package managers de runtimes.

## Redes corporativas

Ambientes com inspeção HTTPS são suportados por um fluxo opcional de CA. O projeto não distribui certificados internos e não desabilita validação TLS.

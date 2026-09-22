# Manual do Usuário — Super Dev Kit v1.0

Este manual foi escrito para quem quer **usar** o Super Dev Kit sem precisar entender a arquitetura interna do projeto.

Se esta é sua primeira vez, siga a ordem deste documento.

## 1. O que é o Super Dev Kit

O Super Dev Kit é uma CLI open source que ajuda a preparar, validar e reproduzir ambientes de desenvolvimento no Windows e Ubuntu/Linux.

Ele pode automatizar ou organizar:

- Git;
- Node.js e npm;
- Python;
- Docker e Docker Compose;
- SSH;
- VS Code e extensões;
- ferramentas SQL;
- stacks de desenvolvimento;
- templates de projeto;
- diagnóstico do ambiente;
- exportação e reprodução de ambientes;
- cleanup controlado;
- inventário e backup.

A ferramenta não substitui essas tecnologias. Ela automatiza a preparação e validação delas.

## 2. Plataformas suportadas

Na v1.0, o foco oficial é:

- Windows 11;
- Windows 10 com winget disponível;
- CMD;
- Windows PowerShell 5.1;
- PowerShell 7;
- Ubuntu 24.04;
- Ubuntu 22.04 em modo compatível;
- Ubuntu em VirtualBox.

WSL 2 possui suporte parcial.

macOS, Fedora e Debian dedicado ainda não fazem parte do suporte oficial.

Consulte [Matriz de suporte](SUPPORT-MATRIX.md).

## 3. Antes de começar

Você precisa de:

- acesso de administrador na máquina quando uma instalação exigir;
- conexão com a internet;
- Git instalado;
- espaço livre suficiente em disco.

### Windows sem Git

~~~powershell
winget install --id Git.Git -e
~~~

Feche e abra o terminal.

### Ubuntu sem Git

~~~bash
sudo apt update
sudo apt install -y git
~~~

## 4. Baixar o Super Dev Kit

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

## 5. Testar sem instalar nada

### CMD

~~~cmd
devkit.cmd version
devkit.cmd help
~~~

### PowerShell

~~~powershell
.\devkit.ps1 version
.\devkit.ps1 help
~~~

### Ubuntu/Linux

~~~bash
bash devkit.sh version
bash devkit.sh help
~~~

Se a versão for exibida, a CLI está acessível.

## 6. Dry-run: sempre comece por aqui

Dry-run mostra o plano sem alterar a máquina.

### Windows

~~~cmd
devkit.cmd setup fullstack --dry-run
~~~

ou:

~~~powershell
.\devkit.ps1 setup fullstack --dry-run
~~~

### Linux

~~~bash
bash devkit.sh setup fullstack --dry-run
~~~

Revise o plano antes de executar a instalação real.

## 7. Escolher um perfil

| Perfil | Use quando |
| --- | --- |
| essential | quer somente a base |
| frontend | trabalha com frontend web |
| backend | trabalha com APIs/backend |
| fullstack | trabalha com frontend + backend |
| datasql | estuda ou trabalha com dados e SQL |
| devops | quer ferramentas focadas em containers e infraestrutura |

Exemplo:

~~~text
devkit setup backend --dry-run
~~~

## 8. Instalação no Windows

Abra CMD ou PowerShell como Administrador quando necessário.

### CMD

~~~cmd
devkit.cmd setup fullstack --dry-run
devkit.cmd setup fullstack
~~~

### PowerShell

~~~powershell
.\devkit.ps1 setup fullstack --dry-run
.\devkit.ps1 setup fullstack
~~~

Depois:

~~~text
devkit doctor
~~~

Se ainda não instalou a CLI global, use devkit.cmd doctor ou .\devkit.ps1 doctor.

## 9. Instalação no Ubuntu/Linux

~~~bash
bash devkit.sh setup fullstack --dry-run
bash devkit.sh setup fullstack
~~~

A CLI chama sudo quando a instalação precisa de privilégios.

Depois:

~~~bash
bash devkit.sh doctor
~~~

Em instalações com Docker, pode ser necessário fazer logout/login, reiniciar ou executar:

~~~bash
newgrp docker
~~~

## 10. Instalar o comando global

Essa etapa é opcional.

### Windows

~~~cmd
devkit.cmd cli install
~~~

Abra um novo terminal e teste:

~~~text
devkit version
~~~

### Linux

~~~bash
bash devkit.sh cli install
~~~

Depois:

~~~bash
devkit version
~~~

O shim global aponta para o clone atual. Se mover a pasta do repositório, execute novamente devkit cli install.

## 11. Dev Doctor

O Dev Doctor verifica a saúde do ambiente.

~~~text
devkit doctor
~~~

Ele pode verificar:

- espaço livre;
- ferramentas essenciais;
- runtimes;
- Docker;
- Docker Compose;
- SSH;
- DNS;
- HTTPS;
- manifesto;
- drift.

Se houver problema, leia também [Troubleshooting](TROUBLESHOOTING.md).

## 12. Stacks

Stacks são conjuntos reutilizáveis de tecnologias.

Exemplos:

~~~text
devkit stack react --dry-run
devkit stack react

devkit stack node-nest --dry-run
devkit stack fullstack-react-node --dry-run
~~~

Use dry-run antes da instalação.

Veja [Stacks](STACKS.md).

## 13. Templates de projeto

Listar:

~~~text
devkit project list
~~~

Criar React + Vite:

~~~text
devkit project react-vite meu-app --dry-run
devkit project react-vite meu-app
~~~

Criar com Dev Container:

~~~text
devkit project react-vite meu-app --with-devcontainer
~~~

Criar Python API:

~~~text
devkit project python-api minha-api
~~~

Criar em outra pasta:

~~~text
devkit project node-nest minha-api --output ./projetos
~~~

O gerador protege diretórios não vazios. Use --force somente quando souber exatamente o que está sobrescrevendo.

## 14. Version managers

Listar adapters:

~~~text
devkit runtime list
~~~

Exemplo:

~~~text
devkit runtime node 22 --manager fnm --dry-run
~~~

O kit não instala version managers automaticamente.

Veja [Version Manager Adapters](VERSION-MANAGERS.md).

## 15. Estado local

~~~text
devkit state
~~~

O manifesto fica em:

~~~text
.super-dev-kit/manifest.json
~~~

Ele registra informações como:

- perfis;
- stacks;
- módulos;
- pacotes;
- runtimes;
- recursos instalados pelo kit;
- itens preexistentes.

A pasta .super-dev-kit é local e não deve ser versionada.

## 16. Reproduzir o ambiente em outra máquina

Na máquina de origem:

~~~text
devkit export
~~~

Isso cria um lock file com a intenção do ambiente.

Na nova máquina:

~~~text
devkit import --dry-run
devkit import
devkit compare
devkit doctor
~~~

O lock file não deve conter senhas, tokens ou conteúdo de certificados.

## 17. Backup

VS Code:

~~~text
devkit backup vscode
~~~

Git:

~~~text
devkit backup git
~~~

Os backups são voltados a configurações seguras e não devem incluir credenciais.

## 18. Inventário

~~~text
devkit inventory
~~~

Use para registrar versões e ferramentas encontradas na máquina.

## 19. Cleanup

Primeiro visualize:

~~~text
devkit cleanup
~~~

Só depois, se estiver correto:

~~~text
devkit cleanup --apply
~~~

O cleanup usa o manifesto para evitar remover itens que já existiam antes do Super Dev Kit.

## 20. Atualizar o Super Dev Kit

~~~text
devkit update
~~~

Ou manualmente:

~~~text
git pull
~~~

O updater evita atualizar quando há alterações locais não salvas.

## 21. Certificado corporativo

A maioria dos usuários **não precisa** desta etapa.

Se Docker e HTTPS funcionarem, ignore certificados.

Se aparecer:

~~~text
x509: certificate signed by unknown authority
~~~

consulte [Certificados corporativos](CERTIFICADOS-CORPORATIVOS.md).

No Linux:

~~~text
devkit setup fullstack --auto-ca
~~~

Nunca use desativação permanente de TLS como solução.

## 22. Docker

Teste:

~~~text
docker version
docker compose version
docker run --rm hello-world
~~~

Se docker ps estiver vazio, isso apenas significa que nenhum container está rodando.

### Linux: permission denied

~~~bash
sudo usermod -aG docker "$USER"
newgrp docker
docker ps
~~~

## 23. Saída JSON para automação

~~~text
devkit version --json
devkit state --json
devkit stack react --dry-run --json
~~~

Exemplo PowerShell:

~~~powershell
$result = devkit version --json | ConvertFrom-Json
$result.data.version
~~~

Exemplo Bash:

~~~bash
devkit version --json | jq -r '.data.version'
~~~

Veja [Automação JSON](JSON-AUTOMATION.md).

## 24. Comandos de referência rápida

| Comando | Função |
| --- | --- |
| devkit setup | prepara um perfil |
| devkit doctor | diagnostica a máquina |
| devkit stack | instala uma stack |
| devkit project | gera um projeto |
| devkit runtime | usa adapter de version manager |
| devkit state | mostra estado local |
| devkit export | exporta ambiente |
| devkit import | reproduz ambiente |
| devkit compare | compara lock e máquina |
| devkit backup | backup de configurações |
| devkit inventory | inventário |
| devkit cleanup | cleanup controlado |
| devkit update | atualiza o kit |
| devkit commands | lista comandos |
| devkit version | mostra versão |
| devkit cli install | instala shim global |
| devkit cli uninstall | remove shim global |

## 25. Fluxos recomendados

### Máquina nova Full Stack

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
devkit.cmd setup fullstack --dry-run
devkit.cmd setup fullstack
devkit.cmd doctor
devkit.cmd cli install
~~~

### Ubuntu/VM

~~~bash
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
bash devkit.sh setup fullstack --dry-run
bash devkit.sh setup fullstack
bash devkit.sh doctor
bash devkit.sh cli install
~~~

### Novo projeto React

~~~text
devkit project react-vite meu-app --dry-run
devkit project react-vite meu-app --with-devcontainer
~~~

### Levar ambiente para outra máquina

~~~text
devkit export
# copiar o lock file
devkit import --dry-run
devkit import
devkit compare
devkit doctor
~~~

## 26. Desinstalar apenas o comando global

~~~text
devkit cli uninstall
~~~

Isso remove o shim da CLI, não os programas instalados.

Para avaliar remoções de ferramentas gerenciadas pelo kit:

~~~text
devkit cleanup
~~~

## 27. Onde procurar ajuda

- [Quick Start](QUICKSTART.md)
- [CLI](CLI.md)
- [FAQ](FAQ.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Matriz de suporte](SUPPORT-MATRIX.md)
- [Certificados corporativos](CERTIFICADOS-CORPORATIVOS.md)

## 28. Como reportar um problema

Antes de abrir uma issue, execute:

~~~text
devkit version
devkit doctor
devkit state
~~~

Inclua:

- plataforma;
- versão do sistema;
- comando executado;
- erro;
- comportamento esperado.

Remova:

- tokens;
- senhas;
- chaves;
- certificados internos;
- dados de clientes;
- qualquer informação privada não necessária.

## 29. Segurança operacional

Use estas regras:

1. execute dry-run primeiro;
2. não execute comandos que você não entendeu;
3. não compartilhe .env real;
4. não publique certificados internos;
5. confira cleanup antes de usar --apply;
6. mantenha backups;
7. mantenha Git e sistema atualizados;
8. revise lock files antes de compartilhar.

## 30. Atualizações futuras

A linha v1.x preservará os contratos públicos sempre que possível.

Mudanças incompatíveis relevantes serão documentadas no changelog e na política de versionamento.

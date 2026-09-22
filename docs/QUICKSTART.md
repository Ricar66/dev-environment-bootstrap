# Quick Start — Super Dev Kit

Este é o fluxo recomendado para preparar uma máquina nova com o Super Dev Kit.

A partir da v0.8, a forma mais simples de usar o projeto é pela CLI unificada \`devkit\`. Os menus e scripts antigos continuam disponíveis.

## 1. Instale o Git

### Windows

~~~powershell
winget install --id Git.Git -e
~~~

Feche e abra o terminal.

### Ubuntu / Linux

~~~bash
sudo apt update
sudo apt install -y git
~~~

## 2. Clone o repositório

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

## 3. Teste a CLI

### Windows — CMD

~~~cmd
devkit.cmd version
devkit.cmd help
~~~

### Windows — PowerShell

~~~powershell
.\devkit.ps1 version
.\devkit.ps1 help
~~~

### Linux

~~~bash
bash devkit.sh version
bash devkit.sh help
~~~

## 4. Faça um dry-run

Antes de instalar qualquer coisa, visualize o plano.

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

Perfis disponíveis:

- essential;
- frontend;
- backend;
- fullstack;
- datasql;
- devops.

Detalhes: [PROFILES.md](PROFILES.md).

## 5. Instale o perfil

### Windows

Abra CMD ou PowerShell como Administrador quando o perfil precisar de recursos elevados.

CMD:

~~~cmd
devkit.cmd setup fullstack
~~~

PowerShell:

~~~powershell
.\devkit.ps1 setup fullstack
~~~

### Linux

~~~bash
bash devkit.sh setup fullstack
~~~

A CLI solicita sudo quando o bootstrap Linux precisa de privilégios.

## 6. Valide com o Dev Doctor

### Windows

~~~cmd
devkit.cmd doctor
~~~

ou:

~~~powershell
.\devkit.ps1 doctor
~~~

### Linux

~~~bash
bash devkit.sh doctor
~~~

Para validar Docker:

~~~text
docker run --rm hello-world
~~~

## 7. Instale o comando global — opcional

Depois de validar o clone, você pode deixar de escrever o launcher completo.

### Windows

~~~cmd
devkit.cmd cli install
~~~

ou:

~~~powershell
.\devkit.ps1 cli install
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

Se ~/.local/bin ainda não estiver no PATH, o instalador mostra como ajustar.

## 8. Use stacks quando quiser um ambiente específico

Listar/usar stacks continua baseado no catálogo modular.

Exemplo:

~~~text
devkit stack react --dry-run
devkit stack react
~~~

Outro exemplo:

~~~text
devkit stack fullstack-react-node --dry-run
~~~

Veja [STACKS.md](STACKS.md).

## 9. Gere projetos

Listar templates:

~~~text
devkit project list
~~~

React + Vite:

~~~text
devkit project react-vite meu-app --dry-run
devkit project react-vite meu-app --with-devcontainer
~~~

Python API:

~~~text
devkit project python-api minha-api
~~~

Veja [PROJECT-TEMPLATES.md](PROJECT-TEMPLATES.md).

## 10. Certificado corporativo é opcional

A maioria das máquinas não precisa de certificado adicional.

Se Docker e HTTPS funcionarem normalmente, ignore esta etapa.

Somente se aparecer algo como:

~~~text
x509: certificate signed by unknown authority
~~~

consulte [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

No Linux, quando necessário:

~~~text
devkit setup fullstack --auto-ca
~~~

O fluxo continua pedindo validação antes de confiar em uma CA.

## 11. Veja o estado local

~~~text
devkit state
~~~

Para automações:

~~~text
devkit state --json
~~~

O manifesto fica em:

~~~text
.super-dev-kit/manifest.json
~~~

## 12. Exporte ou reproduza o ambiente

Exportar:

~~~text
devkit export
~~~

Na outra máquina, primeiro faça dry-run:

~~~text
devkit import --dry-run
~~~

Depois importe:

~~~text
devkit import
~~~

Compare o resultado:

~~~text
devkit compare
~~~

Veja [REPRODUCIBILITY.md](REPRODUCIBILITY.md).

## 13. Backup, inventário e atualização

Backup do VS Code:

~~~text
devkit backup vscode
~~~

Backup da configuração Git segura:

~~~text
devkit backup git
~~~

Inventário:

~~~text
devkit inventory
~~~

Atualização:

~~~text
devkit update
~~~

O updater continua recusando atualizar o clone quando existem alterações locais não salvas.

## 14. Saída JSON

A CLI v0.8 possui uma saída estruturada para automações:

~~~text
devkit version --json
devkit commands --json
devkit doctor --json
devkit stack react --dry-run --json
~~~

Veja [CLI.md](CLI.md) para o contrato, códigos de saída e exemplos.

## Menus antigos continuam disponíveis

Se você preferir a experiência interativa:

### CMD

~~~cmd
setup.cmd
~~~

### PowerShell

~~~powershell
.\setup.ps1
~~~

### Linux

~~~bash
bash setup.sh
~~~

Nenhum fluxo legado foi removido na v0.8.

## Próximo passo

Conheça os guias principais:

- [CLI unificada](CLI.md)
- [Perfis](PROFILES.md)
- [Stacks](STACKS.md)
- [Project Templates](PROJECT-TEMPLATES.md)
- [Ambientes reproduzíveis](REPRODUCIBILITY.md)
- [Automação avançada](AUTOMATION.md)

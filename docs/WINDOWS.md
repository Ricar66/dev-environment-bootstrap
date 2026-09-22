# Windows — CMD e PowerShell

O Super Dev Kit foi preparado para funcionar nos dois shells nativos mais comuns do Windows:

- **Prompt de Comando (CMD)**
- **Windows PowerShell / PowerShell**

Os arquivos `.cmd` são launchers que chamam os scripts PowerShell correspondentes. Dessa forma mantemos uma única lógica de instalação e oferecemos entrada simples para quem prefere CMD.

## Requisitos

- Windows 10 ou Windows 11
- `winget`
- PowerShell disponível no Windows
- privilégios de administrador para instalações
- conexão com a internet

## Primeiro uso

Se o Git ainda não estiver instalado, CMD e PowerShell aceitam:

```text
winget install --id Git.Git -e
```

Depois:

```text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
```

## Menu principal

### CMD

Abra o **Prompt de Comando como Administrador**:

```cmd
setup.cmd
```

### PowerShell

Abra o **PowerShell como Administrador**:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

## Instalação direta por perfil

### CMD

```cmd
windows\setup-windows.cmd -Profile Essential
windows\setup-windows.cmd -Profile Frontend
windows\setup-windows.cmd -Profile Backend
windows\setup-windows.cmd -Profile FullStack
windows\setup-windows.cmd -Profile DataSQL
windows\setup-windows.cmd -Profile DevOps
```

### PowerShell

```powershell
.\windows\setup-windows.ps1 -Profile Essential
.\windows\setup-windows.ps1 -Profile Frontend
.\windows\setup-windows.ps1 -Profile Backend
.\windows\setup-windows.ps1 -Profile FullStack
.\windows\setup-windows.ps1 -Profile DataSQL
.\windows\setup-windows.ps1 -Profile DevOps
```

## Dry-run

Antes de instalar em uma máquina importante, veja o plano.

CMD:

```cmd
windows\setup-windows.cmd -Profile FullStack -DryRun
```

PowerShell:

```powershell
.\windows\setup-windows.ps1 -Profile FullStack -DryRun
```

## Dev Doctor

CMD:

```cmd
diagnostics\dev-doctor.cmd
```

PowerShell:

```powershell
.\diagnostics\dev-doctor.ps1
```

## Configuração JSON

Crie o arquivo local:

CMD:

```cmd
copy config\devkit.config.example.json config\devkit.config.json
```

PowerShell:

```powershell
Copy-Item .\config\devkit.config.example.json .\config\devkit.config.json
```

Execute:

CMD:

```cmd
tools\run-config.cmd
```

PowerShell:

```powershell
.\tools\run-config.ps1
```

Dry-run:

```cmd
tools\run-config.cmd -DryRun
```

```powershell
.\tools\run-config.ps1 -DryRun
```

## Ferramentas auxiliares

| Função | CMD | PowerShell |
| --- | --- | --- |
| Menu principal | `setup.cmd` | `.\setup.ps1` |
| Instalador | `windows\setup-windows.cmd` | `.\windows\setup-windows.ps1` |
| Dev Doctor | `diagnostics\dev-doctor.cmd` | `.\diagnostics\dev-doctor.ps1` |
| Config JSON | `tools\run-config.cmd` | `.\tools\run-config.ps1` |
| VS Code extensions | `tools\install-vscode-extensions.cmd` | `.\tools\install-vscode-extensions.ps1` |
| Inventário | `tools\inventory.cmd` | `.\tools\inventory.ps1` |
| Atualização | `tools\update-devkit.cmd` | `.\tools\update-devkit.ps1` |
| Cleanup | `tools\cleanup.cmd` | `.\tools\cleanup.ps1` |

## Configurando o Git

CMD ou PowerShell:

```text
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"
git config --global init.defaultBranch main
```

Também pode passar ao instalador:

```cmd
windows\setup-windows.cmd -Profile FullStack -GitName "Seu Nome" -GitEmail "seu-email@exemplo.com"
```

## Certificados de rede corporativa

Não instale certificado adicional sem necessidade.

O exportador é PowerShell porque usa o armazenamento nativo de certificados do Windows:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor"
```

Se você estiver no CMD, pode chamar diretamente:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -File certificates\export-root-ca.ps1 -Search "nome-do-emissor"
```

Veja [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

## Observação sobre PowerShell

Os launchers CMD usam:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...
```

Isso **não altera permanentemente** a política de execução do Windows. O bypass vale apenas para aquele processo.

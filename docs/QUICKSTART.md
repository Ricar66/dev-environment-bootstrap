# Quick Start — Super Dev Kit

Este é o fluxo recomendado para preparar uma máquina nova com o Super Dev Kit.

## 1. Instale o Git

### Windows

Abra o PowerShell:

```powershell
winget install --id Git.Git -e
```

Feche e abra o terminal.

### Ubuntu / Linux

```bash
sudo apt update
sudo apt install -y git
```

## 2. Clone o repositório

Windows:

```powershell
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
```

Linux:

```bash
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
```

## 3. Abra o menu

### Windows

Abra o PowerShell como **Administrador**:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

### Linux

```bash
bash setup.sh
```

O menu virou a central de operações do projeto.

## 4. Escolha um perfil

Perfis disponíveis:

- Essential
- Frontend
- Backend
- Full Stack
- Data / SQL
- DevOps

Se não souber qual usar, consulte [PROFILES.md](PROFILES.md).

## 5. Faça um dry-run primeiro

O dry-run mostra o que seria feito sem alterar a máquina.

### Windows

```powershell
.\windows\setup-windows.ps1 -Profile FullStack -DryRun
```

### Linux

```bash
bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --dry-run
```

Depois execute normalmente.

## 6. Instale o perfil

### Windows

```powershell
.\windows\setup-windows.ps1 -Profile FullStack
```

### Linux

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack
```

Ou faça tudo pelo menu principal.

## 7. Valide o ambiente

Windows:

```powershell
.\diagnostics\dev-doctor.ps1
```

Linux:

```bash
bash diagnostics/dev-doctor.sh
```

Para Docker:

```bash
docker run --rm hello-world
```

## 8. Certificado corporativo é opcional

A maioria das máquinas não precisa de certificado adicional.

Se Docker e HTTPS funcionarem, ignore esta etapa.

Somente se aparecer erro como:

```text
x509: certificate signed by unknown authority
```

consulte [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

## 9. Instale extensões do VS Code

Windows:

```powershell
.\tools\install-vscode-extensions.ps1 -Profile FullStack
```

Linux:

```bash
bash tools/install-vscode-extensions.sh --profile fullstack
```

## 10. Configuração automática por JSON

Crie sua configuração local:

### Windows

```powershell
Copy-Item .\config\devkit.config.example.json .\config\devkit.config.json
```

### Linux

```bash
cp config/devkit.config.example.json config/devkit.config.json
```

Edite o JSON e execute pelo menu ou:

Windows:

```powershell
.\tools\run-config.ps1
```

Linux:

```bash
bash tools/run-config.sh
```

Para visualizar antes:

```powershell
.\tools\run-config.ps1 -DryRun
```

ou:

```bash
bash tools/run-config.sh --dry-run
```

## 11. Gere um inventário

Depois da instalação, registre o ambiente:

Windows:

```powershell
.\tools\inventory.ps1
```

Linux:

```bash
bash tools/inventory.sh
```

Os relatórios ficam em `reports/` e não são enviados ao Git.

## 12. Atualize o kit

Windows:

```powershell
.\tools\update-devkit.ps1
```

Linux:

```bash
bash tools/update-devkit.sh
```

O updater recusa atualizar se houver alterações locais não salvas.

## Próximo passo

Conheça a automação completa:

[Automação avançada v0.3](AUTOMATION.md)

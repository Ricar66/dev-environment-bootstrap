# Configurando o Windows

## Requisitos

- Windows 10 ou Windows 11
- PowerShell
- `winget`
- privilégios de administrador
- conexão com a internet

## Execução básica

Abra o PowerShell como Administrador e entre na pasta do repositório:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\windows\setup-windows.ps1
```

O `Set-ExecutionPolicy -Scope Process Bypass` altera a política apenas para aquela sessão do PowerShell.

## Perfis

### Base

```powershell
.\windows\setup-windows.ps1
```

Instala Git, Node.js LTS, VS Code, PowerShell 7, Windows Terminal, GitHub CLI e 7-Zip.

### Docker Desktop

```powershell
.\windows\setup-windows.ps1 -Docker
```

### WSL

```powershell
.\windows\setup-windows.ps1 -WSL
```

Algumas alterações do WSL exigem reinicialização.

### Extras

```powershell
.\windows\setup-windows.ps1 -Extras
```

### Tudo

```powershell
.\windows\setup-windows.ps1 -All
```

## Configurando o Git

Você pode passar sua identidade diretamente:

```powershell
.\windows\setup-windows.ps1 `
  -GitName "Seu Nome" `
  -GitEmail "seu-email@exemplo.com"
```

Ou configurar depois:

```powershell
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"
git config --global init.defaultBranch main
```

## Verificação

Feche e reabra o terminal e execute:

```powershell
git --version
node --version
npm --version
code --version
gh --version
```

Se instalou Docker:

```powershell
docker --version
docker compose version
```

Também é possível executar:

```powershell
.\diagnostics\dev-doctor.ps1
```

# Configurando o Windows

## Requisitos

- Windows 10 ou Windows 11
- PowerShell
- `winget`
- privilégios de administrador
- conexão com a internet

## Primeiro uso

Se o Git ainda não estiver instalado:

```powershell
winget install --id Git.Git -e
```

Depois:

```powershell
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
```

Abra o PowerShell como Administrador:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

A alteração da Execution Policy vale apenas para a sessão atual.

## Perfis

Execução direta:

```powershell
.\windows\setup-windows.ps1 -Profile Essential
.\windows\setup-windows.ps1 -Profile Frontend
.\windows\setup-windows.ps1 -Profile Backend
.\windows\setup-windows.ps1 -Profile FullStack
.\windows\setup-windows.ps1 -Profile DataSQL
.\windows\setup-windows.ps1 -Profile DevOps
```

Para instalar o conjunto mais completo:

```powershell
.\windows\setup-windows.ps1 -All
```

Consulte [PROFILES.md](PROFILES.md) para saber o que cada perfil instala.

## Configurando o Git

Você pode passar sua identidade:

```powershell
.\windows\setup-windows.ps1 -Profile Frontend -GitName "Seu Nome" -GitEmail "seu-email@exemplo.com"
```

Ou configurar manualmente:

```powershell
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"
git config --global init.defaultBranch main
```

## Certificados de rede corporativa

Não instale certificado adicional sem necessidade.

Se uma VM ou ferramenta apresentar erro TLS/x509, descubra o emissor e use:

```powershell
.\certificates\export-root-ca.ps1 -Search "nome-do-emissor"
```

Veja [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

## Verificação

```powershell
.\diagnostics\dev-doctor.ps1
```

Também pode conferir individualmente:

```powershell
git --version
node --version
npm --version
python --version
docker --version
docker compose version
gh --version
```

Nem todos os comandos estarão presentes em todos os perfis.

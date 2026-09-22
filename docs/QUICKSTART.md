# Quick Start — passo a passo

Este guia mostra o caminho mais simples para usar o Super Dev Kit em uma máquina nova.

## 1. Clonar o repositório

### Windows

Se o Git ainda não estiver instalado:

```powershell
winget install --id Git.Git -e
```

Feche e abra o terminal. Depois:

```powershell
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
```

### Ubuntu / Linux

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
```

## 2. Executar no Windows

Abra o **PowerShell como Administrador**:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

Escolha o perfil desejado no menu.

Também é possível executar diretamente:

```powershell
.\windows\setup-windows.ps1 -Profile FullStack
```

## 3. Executar no Ubuntu

Use `bash` para não depender da permissão executável preservada pelo Git:

```bash
bash setup.sh
```

Ou diretamente:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack
```

## 4. Certificado corporativo é opcional

A maioria das máquinas **não precisa instalar certificado adicional**.

Primeiro tente:

```bash
docker run --rm hello-world
```

Se funcionar, não faça nada relacionado a certificados.

Se aparecer:

```text
x509: certificate signed by unknown authority
```

ou:

```text
self-signed certificate in certificate chain
```

a rede provavelmente usa inspeção HTTPS.

Descubra o emissor:

```bash
curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -i issuer
```

Depois siga [Certificados corporativos](CERTIFICADOS-CORPORATIVOS.md).

## 5. Dev Doctor

Windows:

```powershell
.\diagnostics\dev-doctor.ps1
```

Linux:

```bash
bash diagnostics/dev-doctor.sh
```

## 6. Atualizar o Super Dev Kit

Dentro da pasta do projeto:

```bash
git pull
```

ou no PowerShell:

```powershell
git pull
```

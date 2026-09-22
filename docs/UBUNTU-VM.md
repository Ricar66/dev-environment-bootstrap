# Preparando uma VM Ubuntu

## Primeiro uso

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
bash setup.sh
```

O uso de `bash setup.sh` evita depender da permissão executável preservada pelo clone.

## Perfis

Execução direta:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile essential
sudo bash linux/bootstrap-vm-ubuntu.sh --profile frontend
sudo bash linux/bootstrap-vm-ubuntu.sh --profile backend
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack
sudo bash linux/bootstrap-vm-ubuntu.sh --profile datasql
sudo bash linux/bootstrap-vm-ubuntu.sh --profile devops
```

Consulte [PROFILES.md](PROFILES.md).

## O que a base instala

- certificados padrão;
- Git, curl e wget;
- compactação;
- editores de terminal;
- utilitários de sistema;
- ferramentas de rede;
- compiladores básicos;
- OpenSSH Server;
- Docker;
- Docker Compose quando disponível;
- VirtualBox Guest Utilities quando aplicável.

Os perfis adicionam Node.js, Python e clientes de banco conforme necessário.

## Docker sem sudo

O script adiciona o usuário ao grupo `docker`.

Para aplicar na sessão atual:

```bash
newgrp docker
```

Ou reinicie:

```bash
sudo reboot
```

Teste:

```bash
docker ps
docker run --rm hello-world
```

## SSH

Veja o IP:

```bash
hostname -I
```

Confira:

```bash
systemctl status ssh
```

A partir do Windows:

```powershell
ssh usuario@IP_DA_VM
```

## Certificado corporativo opcional

Primeiro teste Docker normalmente. Se houver erro `x509`, você pode importar uma CA autorizada:

```bash
sudo bash certificates/import-ca-linux.sh --auto
```

Ou passar diretamente ao bootstrap:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --ca /caminho/certificado.cer
```

Veja [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

## Diagnóstico

```bash
bash diagnostics/dev-doctor.sh
```

# Preparando uma VM Ubuntu

## Execução

```bash
chmod +x linux/bootstrap-vm-ubuntu.sh
sudo ./linux/bootstrap-vm-ubuntu.sh
```

O script usa `apt` e foi pensado para Ubuntu/Debian.

## O que é instalado

- certificados padrão (`ca-certificates`)
- Git
- curl e wget
- compactação
- editores de terminal
- utilitários de sistema
- ferramentas de rede
- compiladores básicos
- OpenSSH Server
- Docker
- Docker Compose, quando disponível
- VirtualBox Guest Utilities, quando aplicável

## Usando Docker sem `sudo`

O script adiciona o usuário ao grupo `docker`.

Para aplicar na sessão atual:

```bash
newgrp docker
```

Ou reinicie a VM:

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

Confira o serviço:

```bash
systemctl status ssh
```

A partir do computador host:

```powershell
ssh usuario@IP_DA_VM
```

## Diagnóstico

```bash
bash diagnostics/dev-doctor.sh
```

## Rede corporativa

Se o Docker apresentar erro `x509`, consulte [Certificados corporativos](CERTIFICADOS-CORPORATIVOS.md).

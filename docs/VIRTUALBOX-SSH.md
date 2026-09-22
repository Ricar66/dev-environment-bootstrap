# VirtualBox + SSH

Para VMs Ubuntu Server, trabalhar por SSH costuma ser mais confortável do que digitar comandos diretamente no console do VirtualBox.

## 1. Rede da VM

No VirtualBox:

1. desligue a VM;
2. abra **Configurações > Rede**;
3. selecione **Placa em modo Bridge**;
4. escolha a interface de rede usada pelo host;
5. marque **Cabo conectado**.

> Em ambientes onde Bridge não é permitido, NAT com redirecionamento de porta também é uma alternativa.

## 2. SSH na VM

O script Ubuntu instala e ativa o OpenSSH Server.

Confira:

```bash
systemctl status ssh
```

Veja o IP:

```bash
hostname -I
```

O endereço `172.17.0.1`, quando presente, costuma ser a bridge interna do Docker. Use o IP da interface da rede local para conectar a partir do host.

## 3. Conexão pelo Windows

No PowerShell:

```powershell
ssh usuario@IP_DA_VM
```

Exemplo:

```powershell
ssh aluno@192.168.1.50
```

Na primeira conexão, confirme a fingerprint apenas se o endereço e a máquina forem os esperados.

## 4. Pasta compartilhada

Com Guest Additions/Guest Utilities instalados, uma pasta compartilhada chamada `Downloads` normalmente aparece como:

```bash
/media/sf_Downloads
```

O usuário pode precisar estar no grupo:

```bash
sudo usermod -aG vboxsf $USER
```

Depois faça logout/login ou reinicie.

# Troubleshooting

Problemas comuns encontrados ao preparar Windows, Ubuntu, VirtualBox e Docker.

## Docker: permission denied em /var/run/docker.sock

Sintoma:

```text
permission denied while trying to connect to the Docker daemon socket
```

Correção:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Ou faça logout/login ou reinicie a VM.

Teste:

```bash
docker ps
```

## Docker Hub: x509 / unknown authority

Sintoma:

```text
x509: certificate signed by unknown authority
```

Diagnóstico:

```bash
curl -vk https://registry-1.docker.io/v2/ 2>&1 | grep -i issuer
```

Não desabilite TLS permanentemente. Consulte [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

## Conflito docker-compose-v2 x docker-compose-plugin

Sintoma típico:

```text
trying to overwrite ... docker-compose, which is also in package ...
```

O bootstrap atual evita instalar duas implementações concorrentes.

Se uma máquina já ficou com o apt quebrado:

```bash
sudo apt --fix-broken install -y
sudo dpkg --configure -a
```

Depois verifique:

```bash
docker compose version
```

## apt/dpkg: Permission denied ou "você é root?"

Use `sudo`:

```bash
sudo apt --fix-broken install -y
```

```bash
sudo dpkg --configure -a
```

## Script .sh: Permission denied

Você não precisa tornar o arquivo executável se chamar o Bash diretamente:

```bash
bash setup.sh
```

Para um script que exige root:

```bash
sudo bash linux/bootstrap-vm-ubuntu.sh --profile fullstack
```

## Pasta compartilhada do VirtualBox não aparece

Confira:

```bash
ls /media
```

Pastas compartilhadas automáticas normalmente aparecem como:

```text
/media/sf_NOME
```

Garanta que Guest Utilities estão instaladas e que o usuário pertence ao grupo `vboxsf`:

```bash
sudo apt install -y virtualbox-guest-utils
sudo usermod -aG vboxsf $USER
```

Depois faça logout/login ou reinicie.

## SSH não conecta à VM

Confira o serviço:

```bash
systemctl status ssh
```

Veja os IPs:

```bash
hostname -I
```

O endereço `172.17.0.1` normalmente pertence à bridge interna do Docker e não é o IP que você deve usar a partir do Windows.

No VirtualBox, Bridge costuma facilitar o acesso pela rede local. NAT com port forwarding também é uma alternativa.

## winget não encontrado

No Windows, o `winget` faz parte do App Installer.

Atualize/instale o App Installer e reabra o terminal.

## VS Code instalado, mas "code" não existe

Feche e abra o terminal depois de instalar o VS Code.

Se necessário, abra o VS Code uma vez para finalizar a configuração de PATH.

## WSL precisa de reinicialização

Algumas alterações de virtualização e recursos opcionais do Windows só ficam ativas após reiniciar.

Depois:

```powershell
wsl --status
```

## O Super Dev Kit não atualiza

O updater recusa atualizar se houver alterações locais:

```bash
git status
```

Salve suas alterações com commit/stash ou descarte-as conscientemente antes de tentar novamente.

## Como coletar informações para uma issue

Execute:

Linux:

```bash
bash diagnostics/dev-doctor.sh
bash tools/inventory.sh
```

Windows:

```powershell
.\diagnostics\dev-doctor.ps1
.\tools\inventory.ps1
```

Antes de publicar o inventário, remova nomes de host, caminhos, certificados, IPs internos ou outros dados sensíveis que você não queira compartilhar.

# Automação avançada — Super Dev Kit v0.3

A v0.3 adiciona recursos para tornar o Super Dev Kit mais previsível, reutilizável e seguro em máquinas novas.

## 1. Dry-run

O dry-run mostra o plano sem alterar a máquina.

### Windows

```powershell
.\windows\setup-windows.ps1 -Profile FullStack -DryRun
```

### Linux

```bash
bash linux/bootstrap-vm-ubuntu.sh --profile fullstack --dry-run
```

Use dry-run antes de executar o kit em uma máquina importante ou corporativa.

## 2. Configuração declarativa

Copie o exemplo:

### Windows

```powershell
Copy-Item .\config\devkit.config.example.json .\config\devkit.config.json
```

### Linux

```bash
cp config/devkit.config.example.json config/devkit.config.json
```

Edite:

```json
{
  "profile": "fullstack",
  "install_vscode_extensions": true,
  "git": {
    "name": "Seu Nome",
    "email": "voce@exemplo.com"
  },
  "features": {
    "docker": true,
    "wsl": true,
    "extras": false
  },
  "certificate": {
    "auto": false,
    "path": ""
  }
}
```

O arquivo local é ignorado pelo Git.

### Executar

Windows:

```powershell
.\tools\run-config.ps1
```

Linux:

```bash
bash tools/run-config.sh
```

### Dry-run do JSON

Windows:

```powershell
.\tools\run-config.ps1 -DryRun
```

Linux:

```bash
bash tools/run-config.sh --dry-run
```

## 3. Extensões do VS Code por perfil

Windows:

```powershell
.\tools\install-vscode-extensions.ps1 -Profile FullStack
```

Linux:

```bash
bash tools/install-vscode-extensions.sh --profile fullstack
```

Também existe dry-run:

```bash
bash tools/install-vscode-extensions.sh --profile fullstack --dry-run
```

Os perfis instalam apenas extensões relacionadas ao objetivo do ambiente.

## 4. Auto-update seguro

O update só é executado quando o clone não possui alterações locais pendentes.

Windows:

```powershell
.\tools\update-devkit.ps1
```

Linux:

```bash
bash tools/update-devkit.sh
```

O updater usa `git pull --ff-only` para evitar merges automáticos inesperados.

## 5. Inventário do ambiente

Gera um relatório local com versões e ferramentas detectadas.

Windows:

```powershell
.\tools\inventory.ps1
```

Linux:

```bash
bash tools/inventory.sh
```

Os relatórios são salvos em:

```text
reports/
```

Essa pasta é ignorada pelo Git.

O inventário pode conter nomes de host, versões e detalhes da máquina. Revise o arquivo antes de compartilhá-lo.

## 6. Cleanup / uninstall controlado

O cleanup começa sempre em modo de visualização.

Linux:

```bash
bash tools/cleanup.sh --profile fullstack
```

Windows:

```powershell
.\tools\cleanup.ps1 -Profile FullStack
```

Para realmente remover, é necessário usar a opção explícita de aplicação e confirmar.

Linux:

```bash
sudo bash tools/cleanup.sh --profile fullstack --apply
```

Windows:

```powershell
.\tools\cleanup.ps1 -Profile FullStack -Apply
```

### Observação importante

O Super Dev Kit ainda não mantém um banco de estado dizendo se um pacote já existia antes da primeira execução.

Por isso, o cleanup mostra exatamente o que pretende remover e exige confirmação.

Docker também não é removido por padrão.

## 7. Certificados

Certificados corporativos continuam opcionais.

O kit não inclui CAs privadas ou internas no repositório. Ele apenas fornece:

- exportador seguro no Windows;
- importador no Linux;
- pasta local ignorada pelo Git;
- diagnóstico TLS.

Veja [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

## 8. Fluxo recomendado

Para uma máquina nova:

1. clone o Super Dev Kit;
2. execute o Dev Doctor;
3. faça um dry-run do perfil;
4. execute a instalação;
5. instale extensões do VS Code;
6. execute o Dev Doctor novamente;
7. gere um inventário;
8. use os exemplos Docker para validar o ambiente.

Esse fluxo deixa a configuração mais fácil de reproduzir e diagnosticar.

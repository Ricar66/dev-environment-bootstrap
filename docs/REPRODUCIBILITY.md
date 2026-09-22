# Ambientes reproduzíveis — v0.6

A v0.6 adiciona uma camada de **reprodutibilidade** ao Super Dev Kit.

O objetivo não é fingir que Windows e Linux possuem os mesmos pacotes ou os mesmos versionadores. O kit registra a intenção do ambiente, exporta essa intenção para um lock file e depois verifica diferenças na máquina de destino.

## Conceitos

### Manifesto local

O manifesto continua representando **esta máquina**:

```text
.super-dev-kit/manifest.json
```

Na v0.6 ele usa schema 2 e passa a registrar também:

- stacks;
- módulos;
- versões de runtime observadas;
- restrições desejadas.

### Lock file

O lock file representa um ambiente que pode ser levado para outra máquina.

Formato padrão:

```text
.super-dev-kit/devkit.lock.json
```

Ele contém somente metadados não secretos:

- versão do Super Dev Kit;
- plataforma de origem;
- perfis;
- stacks;
- módulos;
- constraints de runtimes;
- pacotes instalados pelo kit na plataforma de origem;
- extensões VS Code.

Ele **não inclui** senhas, tokens, chaves privadas ou conteúdo de certificados.

## Exportar ambiente

### CMD

```cmd
tools\export-environment.cmd
```

### PowerShell

```powershell
.\tools\export-environment.ps1
```

### Linux

```bash
bash tools/export-environment.sh
```

Também é possível escolher outro caminho:

```powershell
.\tools\export-environment.ps1 -OutputPath .\meu-ambiente.lock.json
```

```bash
bash tools/export-environment.sh --output ./meu-ambiente.lock.json
```

## Importar ambiente

Sempre faça dry-run primeiro.

CMD:

```cmd
tools\import-environment.cmd -LockPath .\meu-ambiente.lock.json -DryRun
```

PowerShell:

```powershell
.\tools\import-environment.ps1 -LockPath .\meu-ambiente.lock.json -DryRun
```

Linux:

```bash
bash tools/import-environment.sh --lock ./meu-ambiente.lock.json --dry-run
```

Depois execute sem dry-run.

Quando o lock possui stacks, a importação prefere as stacks porque elas são portáveis entre Windows e Linux. Pacotes específicos da plataforma são usados como fallback quando necessário.

## Comparar máquina x lock

CMD:

```cmd
tools\compare-environment.cmd -LockPath .\meu-ambiente.lock.json
```

PowerShell:

```powershell
.\tools\compare-environment.ps1 -LockPath .\meu-ambiente.lock.json
```

Linux:

```bash
bash tools/compare-environment.sh --lock ./meu-ambiente.lock.json
```

O comparador verifica:

- stacks;
- módulos;
- pacotes da plataforma;
- extensões VS Code;
- constraints de runtimes.

Quando encontra diferença, retorna código 2 para permitir uso em automações.

## Constraints de runtimes

No `config/devkit.config.json`:

```json
{
  "runtime_versions": {
    "node": ">=22",
    "python": "3.13",
    "dotnet": "major:10",
    "java": ">=21",
    "php": "8.4"
  }
}
```

Formatos suportados:

| Constraint | Significado |
| --- | --- |
| `3.13` | versão 3.13.x |
| `major:24` | major exatamente 24 |
| `>=8` | versão 8 ou superior |
| `>=21.0` | versão 21.0 ou superior |

Validação:

CMD:

```cmd
tools\check-runtime-versions.cmd -ConfigPath .\config\devkit.config.json
```

PowerShell:

```powershell
.\tools\check-runtime-versions.ps1 -ConfigPath .\config\devkit.config.json
```

Linux:

```bash
bash tools/check-runtime-versions.sh --config config/devkit.config.json
```

## Presets de compatibilidade

O projeto fornece presets em:

```text
versions/presets.json
```

Exemplos:

```powershell
.\tools\check-runtime-versions.ps1 -Preset portable
.\tools\check-runtime-versions.ps1 -Preset modern
```

```bash
bash tools/check-runtime-versions.sh --preset portable
bash tools/check-runtime-versions.sh --preset modern
```

Esses nomes representam políticas definidas pelo próprio projeto; não são afirmações de que uma versão específica é a versão oficial mais recente de cada runtime.

## Por que constraints em vez de forçar patch versions?

`winget`, `apt` e distribuições Linux não possuem o mesmo catálogo de versões.

Forçar uma versão exata sem que ela exista no gerenciador da máquina tornaria o bootstrap frágil.

Por isso a v0.6 faz duas coisas:

1. instala usando os mecanismos estáveis já existentes do Super Dev Kit;
2. valida se o resultado atende a política configurada.

Adapters de version managers para pinning mais forte podem ser adicionados em uma versão futura sem quebrar esse modelo.

## Fluxo recomendado

```text
Máquina A
   │
   ├─ instala stack
   ├─ Dev Doctor
   └─ export-environment
            │
            ▼
      devkit.lock.json
            │
            ▼
Máquina B
   │
   ├─ import --dry-run
   ├─ import
   ├─ compare-environment
   └─ Dev Doctor
```

## Segurança

Antes de compartilhar um lock file, ainda é recomendável revisá-lo. O formato foi projetado para não conter segredos, mas pacotes e nomes de stacks podem revelar informações sobre a finalidade do ambiente.

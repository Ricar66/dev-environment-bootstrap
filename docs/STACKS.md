# Stacks

Stacks são presets de desenvolvimento que combinam perfil base + módulos.

Elas ficam em:

```text
stacks/
```

## Presets atuais

| Stack | Foco |
| --- | --- |
| React | Frontend React/Node |
| Node + NestJS | APIs Node/NestJS |
| Full Stack React + Node | React + NestJS + SQL |
| Python | Python + pip + venv |
| .NET | C#/.NET + Docker |
| Java | JDK + Docker |
| PHP | PHP + Composer + Docker |
| Data / SQL | Python + SQL + Docker |
| DevOps | Docker + YAML + SSH |

## Stack Wizard

### Windows CMD

```cmd
tools\stack-wizard.cmd
```

Dry-run:

```cmd
tools\stack-wizard.cmd -DryRun
```

### Windows PowerShell

```powershell
.\tools\stack-wizard.ps1
```

```powershell
.\tools\stack-wizard.ps1 -DryRun
```

### Linux

```bash
bash tools/stack-wizard.sh
```

```bash
bash tools/stack-wizard.sh --dry-run
```

## Instalação direta

React:

```cmd
tools\install-stack.cmd -Stack react -DryRun
tools\install-stack.cmd -Stack react
```

PowerShell:

```powershell
.\tools\install-stack.ps1 -Stack react -DryRun
.\tools\install-stack.ps1 -Stack react
```

Linux:

```bash
bash tools/install-stack.sh --stack react --dry-run
bash tools/install-stack.sh --stack react
```

## Formato do preset

```json
{
  "name": "Full Stack React + Node",
  "slug": "fullstack-react-node",
  "description": "React no frontend, Node/NestJS no backend, Docker e SQL.",
  "base_profile": "fullstack",
  "modules": ["react", "nestjs", "sql"]
}
```

O preset não repete listas de pacotes. Ele apenas referencia módulos, mantendo a configuração centralizada no catálogo.

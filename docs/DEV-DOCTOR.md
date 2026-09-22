# Dev Doctor v2

O Dev Doctor da v0.5 funciona como um check-up do ambiente.

Ele verifica somente os checks aplicáveis e apresenta:

- categoria;
- status;
- detalhe;
- sugestão de correção;
- score final.

## Executar

CMD:

```cmd
diagnostics\dev-doctor.cmd
```

PowerShell:

```powershell
.\diagnostics\dev-doctor.ps1
```

Linux:

```bash
bash diagnostics/dev-doctor.sh
```

## Categorias

### Sistema

Espaço livre e informações básicas.

### Core

Ferramentas essenciais como Git, curl, winget/jq.

### Runtime

Node, npm, Python e VS Code quando presentes.

### Docker

CLI, daemon, Compose e permissões.

### Rede

DNS e conexão HTTPS com o Docker Registry.

### Estado

Validade do manifesto da v0.4 e detecção de **drift**.

Drift significa que o manifesto diz que uma ferramenta gerenciada deveria estar presente, mas ela desapareceu da máquina.

## Score

O score considera os checks aplicáveis:

```text
Score:    92%
Checks:   13
OK:       12
Avisos:   1
Falhas:   0
```

Itens opcionais que não fazem parte do ambiente são exibidos como `SKIP` e não reduzem a pontuação.

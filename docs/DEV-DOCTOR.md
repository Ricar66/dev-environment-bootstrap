# Dev Doctor v3

O Dev Doctor é o check-up do ambiente do Super Dev Kit.

A v3 mantém o comportamento seguro das versões anteriores e melhora **explicação, diagnóstico e automação**.

## Princípio

O Doctor é **somente leitura**.

Ele pode sugerir comandos de correção, mas não executa automaticamente reparos, instalações, remoções ou alterações de configuração.

## Executar

CLI recomendada:

~~~text
devkit doctor
~~~

Diagnóstico detalhado:

~~~text
devkit doctor --verbose
~~~

Saída estruturada:

~~~text
devkit doctor --json
~~~

Combinar detalhes e JSON:

~~~text
devkit doctor --verbose --json
~~~

Os scripts diretos continuam disponíveis:

### PowerShell

~~~powershell
.\diagnostics\dev-doctor.ps1
.\diagnostics\dev-doctor.ps1 -VerboseOutput
.\diagnostics\dev-doctor.ps1 -Json
~~~

### Linux

~~~bash
bash diagnostics/dev-doctor.sh
bash diagnostics/dev-doctor.sh --verbose
bash diagnostics/dev-doctor.sh --json
~~~

## O que mudou na v3

### Causa provável

Warnings e falhas podem explicar por que o problema costuma acontecer.

Exemplo:

~~~text
[FALHA]   Docker       Daemon
          Causa provável: A CLI existe, mas não conseguiu conversar com o daemon.
          Sugestão: Abra/reinicie o Docker e tente novamente.
          Verifique: docker info
~~~

A causa é uma hipótese diagnóstica, não uma afirmação absoluta.

### Comando de verificação

Com `--verbose`, o Doctor mostra um comando que ajuda o usuário a confirmar o problema antes de alterar a máquina.

### Health

O resumo inclui um estado simples:

~~~text
healthy
warning
failed
~~~

- `healthy`: nenhum warning/failure aplicável;
- `warning`: não há falhas, mas existem pontos de atenção;
- `failed`: pelo menos um check obrigatório falhou.

### JSON estruturado

O Doctor v3 produz checks estruturados dentro do envelope público da CLI.

Exemplo reduzido:

~~~json
{
  "schema_version": 1,
  "command": "doctor",
  "success": true,
  "exit_code": 0,
  "data": {
    "doctor_version": 3,
    "platform": "linux",
    "health": "warning",
    "score": 92,
    "summary": {
      "checks": 13,
      "passed": 12,
      "warnings": 1,
      "failed": 0
    },
    "checks": [
      {
        "category": "Docker",
        "name": "Grupo docker",
        "status": "WARN",
        "cause": "O usuário atual não pertence ao grupo docker; comandos sem sudo podem falhar.",
        "hint": "sudo usermod -aG docker $USER && newgrp docker",
        "verify": "id -nG $USER"
      }
    ]
  }
}
~~~

`success: true` significa que o diagnóstico foi executado corretamente. A saúde do ambiente é representada por `data.health`, `summary` e pelos checks.

Isso preserva compatibilidade com o comportamento histórico do Doctor, que não transforma automaticamente warnings do ambiente em erro da própria CLI.

## Categorias

### Sistema

Espaço livre e informações básicas.

### Core

Ferramentas essenciais, como Git, curl, winget e jq.

### Runtime

Runtimes e ferramentas opcionais detectadas no ambiente.

### Docker

CLI, daemon, Compose e, no Linux, acesso pelo grupo docker.

### SSH / WSL

No Linux, verifica disponibilidade/serviço SSH.

No Windows, verifica o status do WSL quando disponível.

### Rede

DNS e HTTPS para o Docker Registry.

Falhas podem envolver:

- DNS;
- VPN;
- proxy;
- firewall;
- inspeção HTTPS;
- CA corporativa.

O Doctor não recomenda desabilitar TLS.

### Estado

Valida o manifesto local e procura drift de pacotes gerenciados.

## Score

O score considera apenas checks aplicáveis. Itens `SKIP` não reduzem a pontuação.

~~~text
Saúde:    warning
Score:    92%
Checks:   13
OK:       12
Avisos:   1
Falhas:   0
~~~

## Como usar em suporte

Antes de abrir uma issue:

~~~text
devkit version
devkit info
devkit doctor --verbose
devkit state
~~~

Para automação ou coleta estruturada:

~~~text
devkit doctor --json
~~~

Revise qualquer saída antes de compartilhá-la publicamente.

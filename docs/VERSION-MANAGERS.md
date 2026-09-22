# Version Manager Adapters — v0.7

A v0.7 adiciona uma camada opcional para usar version managers já presentes na máquina.

O Super Dev Kit **não baixa nem executa instaladores remotos de version managers automaticamente**.

Isso mantém o fluxo previsível e evita transformar um bootstrap confiável em uma sequência de scripts externos executados sem revisão.

## Adapters

| Runtime | Adapters |
| --- | --- |
| Node.js | fnm, nvm |
| Python | pyenv |
| .NET SDK | dotnet-install |
| Java | sdkman |
| PHP | phpenv |

Todos possuem fallback native.

## Listar managers

CMD:

~~~cmd
tools\runtime-manager.cmd -List
~~~

PowerShell:

~~~powershell
.\tools\runtime-manager.ps1 -List
~~~

Linux:

~~~bash
bash tools/runtime-manager.sh --list
~~~

## Dry-run

Exemplo com Node.js:

~~~powershell
.\tools\runtime-manager.ps1 -Runtime node -Version 22 -Manager fnm -DryRun
~~~

Linux:

~~~bash
bash tools/runtime-manager.sh --runtime node --version 22 --manager fnm --dry-run
~~~

## Auto

Com auto, o kit escolhe o primeiro adapter compatível que já estiver disponível.

~~~bash
bash tools/runtime-manager.sh --runtime python --version 3.13.1 --manager auto
~~~

Se nenhum manager for encontrado, o fluxo cai para native sem quebrar a instalação.

Nesse caso o kit orienta usar o instalador normal da stack e depois validar a constraint com o runtime checker da v0.6.

## Pinning

Quando o manager suporta seleção explícita, o adapter executa o pinning correspondente.

Exemplos conceituais:

~~~text
fnm    -> install + default
nvm    -> install + use
pyenv  -> install + global
sdkman -> install java + default java
phpenv -> install + global
~~~

Para sdkman, use o identificador de versão aceito pelo SDKMAN instalado na sua máquina, por exemplo um identificador específico de distribuição.

## .NET

O adapter dotnet-install é usado somente quando esse comando já está disponível.

O Super Dev Kit não baixa o script dotnet-install automaticamente.

Sem ele, o fluxo usa fallback nativo e a constraint continua sendo validada pelo check-runtime-versions.

## Diferença entre constraint e manager

A v0.6 responde:

> Minha máquina atende à versão esperada?

A v0.7 adiciona:

> Se eu já uso um version manager, o Super Dev Kit consegue pedir uma versão específica a ele?

São responsabilidades diferentes e complementares.

## Segurança

O parâmetro de versão aceita apenas letras, números, ponto, hífen, underscore e +.

Os comandos são montados como arrays de argumentos. Não usamos eval.

Isso evita que o campo de versão seja interpretado como comando arbitrário.

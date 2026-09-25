# Padrão de comentários

Comentários do Super Dev Kit existem para explicar **intenção, contrato e risco**.

Não devemos transformar scripts em documentos linha por linha.

## PowerShell

Scripts executáveis importantes devem, quando fizer sentido, começar com comment-based help:

~~~powershell
<#
.SYNOPSIS
    Resumo de uma linha.

.DESCRIPTION
    Responsabilidade do script e limites.

.PARAMETER DryRun
    O que muda quando a opção é usada.

.EXAMPLE
    .\tool.ps1 -DryRun

.NOTES
    Side effects, códigos de saída ou compatibilidade importante.
#>
~~~

Funções públicas ou complexas devem explicar comportamento quando o nome e os parâmetros não forem suficientes.

## Bash

Use um bloco curto antes de funções importantes:

~~~bash
# install_module
#
# Purpose:
#   Instala um módulo já resolvido pelo catálogo.
#
# Arguments:
#   $1 - id do módulo.
#
# Returns:
#   0 em sucesso; código não zero em falha.
#
# Side effects:
#   Pode instalar pacotes e atualizar o manifesto.
install_module() {
  ...
}
~~~

## Comentar

Comente quando houver:

- decisão não óbvia;
- fallback;
- regra de compatibilidade;
- comportamento diferente entre Windows/Linux;
- alteração do sistema;
- privilégio elevado;
- código de saída relevante;
- proteção contra perda de dados;
- sanitização ou regra de segurança;
- contrato público.

## Não comentar

Evite:

~~~powershell
# Incrementa i
$i++
~~~

ou:

~~~bash
# Define profile
profile="fullstack"
~~~

O código já comunica isso.

## TODO

Todo TODO deve explicar condição de remoção ou apontar para issue.

Bom:

~~~text
TODO(#24): remover fallback quando o Dev Doctor v3 usar o novo formato em ambas as plataformas.
~~~

Ruim:

~~~text
TODO: melhorar
~~~

## Comentários e documentação

Se uma explicação for necessária para **usar** o recurso, ela pertence ao manual/CLI.

Se for necessária para **manter** o recurso, pertence ao código ou a INTERNALS.md.

Se define um **contrato público**, deve existir também em documentação versionada.

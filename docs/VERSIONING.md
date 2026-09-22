# Versionamento e compatibilidade

O Super Dev Kit usa **Semantic Versioning** a partir da v1.0.0.

Formato:

~~~text
MAJOR.MINOR.PATCH
~~~

## PATCH

Correções compatíveis:

~~~text
1.0.0 -> 1.0.1
~~~

Exemplos:

- correção de parser;
- mensagem de erro;
- documentação;
- bug sem mudança de contrato.

## MINOR

Novas funcionalidades compatíveis:

~~~text
1.0.0 -> 1.1.0
~~~

Exemplos:

- nova stack;
- novo template;
- novo comando opcional;
- novo adapter.

## MAJOR

Mudança incompatível:

~~~text
1.x -> 2.0.0
~~~

Exemplos:

- remoção de comando;
- mudança incompatível de argumentos;
- mudança incompatível no schema JSON;
- mudança incompatível em lock file ou manifesto.

## Contratos públicos da v1

A linha v1 considera públicos:

- nomes principais dos comandos devkit;
- códigos de saída documentados;
- envelope JSON schema_version 1;
- manifesto schema_version 2;
- lock file usado pela reprodução de ambiente;
- nomes públicos de perfis;
- nomes publicados de stacks e templates.

## Depreciação

Quando possível, uma funcionalidade será marcada como deprecated antes de ser removida.

Remoções incompatíveis devem ocorrer em versão MAJOR.

## Scripts legados

Wrappers CMD, PowerShell e Bash existentes permanecem suportados durante a linha v1 enquanto a documentação os listar como compatíveis.

## Suporte de versões

A manutenção principal acompanha a última MINOR da linha v1.

Correções críticas podem ser aplicadas à versão estável anterior quando forem simples e seguras, mas o projeto não promete manutenção indefinida de todas as versões antigas.

## Changelog

Mudanças públicas devem ser registradas em CHANGELOG.md.

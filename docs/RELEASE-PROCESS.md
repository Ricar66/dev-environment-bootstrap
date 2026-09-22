# Processo de Release

Este documento define o processo recomendado a partir da v1.0.

## 1. Preparar branch de release

Exemplo:

~~~text
release/v1.0.0
~~~

## 2. Atualizar versão

Atualize:

- VERSION;
- CHANGELOG.md;
- README.md;
- release notes em docs/releases/.

## 3. Validar documentação

~~~text
python tools/check-docs.py
~~~

## 4. Validar CLI

Windows:

~~~text
devkit.cmd version
devkit.cmd commands
devkit.cmd setup fullstack --dry-run
devkit.cmd doctor
~~~

Linux:

~~~text
bash devkit.sh version
bash devkit.sh commands
bash devkit.sh setup fullstack --dry-run
bash devkit.sh doctor
~~~

## 5. Aguardar CI

Os workflows principais devem estar verdes:

- Validate Super Dev Kit;
- Public Readiness.

## 6. Merge

Faça merge somente depois da validação.

## 7. Confirmar main

Após merge, aguarde a CI da main.

## 8. Criar tag

~~~text
v1.0.0
~~~

A tag deve apontar para o commit validado da main.

## 9. Criar GitHub Release

Use as release notes versionadas em docs/releases/.

## 10. Publicar

Depois da release estável:

- atualizar post do LinkedIn;
- publicar artigo;
- adicionar screenshots reais;
- divulgar good first issues.

## Hotfix

Correção urgente compatível:

~~~text
release/v1.0.1
~~~

## Regra principal

Nunca tague uma versão cuja main esteja vermelha.

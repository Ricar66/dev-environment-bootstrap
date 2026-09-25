# Schemas JSON públicos

A v1.1 formaliza em JSON Schema os formatos que já existiam na linha v1.

O objetivo não é redesenhar os arquivos, e sim tornar seus contratos verificáveis por CI, editores e integrações.

## Schemas

~~~text
schemas/
├── config-v1.schema.json
├── manifest-v2.schema.json
├── environment-lock-v1.schema.json
└── cli-envelope-v1.schema.json
~~~

## Config v1

Arquivo típico:

~~~text
config/devkit.config.json
~~~

Schema:

~~~text
schemas/config-v1.schema.json
~~~

O schema cobre perfis, runtimes desejados, Git, features, certificado, proxy e customizações.

## Manifest v2

Arquivo local:

~~~text
.super-dev-kit/manifest.json
~~~

Schema:

~~~text
schemas/manifest-v2.schema.json
~~~

O manifesto representa estado local observado/gerenciado e não deve ser compartilhado como se fosse um lock file portátil.

## Environment lock v1

Arquivo padrão:

~~~text
.super-dev-kit/devkit.lock.json
~~~

Schema:

~~~text
schemas/environment-lock-v1.schema.json
~~~

O lock file descreve intenção portátil entre máquinas.

## CLI envelope v1

Comandos com `--json` usam o envelope público schema v1.

Schema:

~~~text
schemas/cli-envelope-v1.schema.json
~~~

Campos-base:

- `schema_version`;
- `command`;
- `success`;
- `exit_code`;
- `timestamp`;
- `data` quando houver dados estruturados;
- `output` quando uma ferramenta delegada ainda produzir texto.

## Compatibilidade

Durante a linha v1:

- campos obrigatórios não devem ser removidos de forma incompatível;
- mudanças incompatíveis de schema exigem revisão da política de versionamento;
- o número do schema é independente da versão do produto;
- novos campos devem ser adicionados com intenção clara e documentação.

## Validar no projeto

A CI usa a biblioteca Python `jsonschema`.

Localmente:

~~~bash
python -m pip install "jsonschema>=4.18,<5"
python tools/check-contracts.py
~~~

O teste valida:

- config de exemplo;
- fixture de manifesto v2;
- fixture de lock v1;
- fixture de envelope CLI v1;
- uma fixture propositalmente inválida para comprovar que erros são rejeitados.

## Regra de evolução

Antes de mudar um formato:

1. altere a implementação;
2. atualize o schema correspondente;
3. atualize/adicione fixtures;
4. execute `tools/check-contracts.py`;
5. documente a compatibilidade no changelog quando a mudança for pública.

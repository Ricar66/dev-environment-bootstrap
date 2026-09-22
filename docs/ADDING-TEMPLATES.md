# Como adicionar um template

Templates criam projetos iniciais locais.

## 1. Crie a pasta

~~~text
templates/meu-template/
~~~

## 2. Registre no catálogo

Edite templates/catalog.json e declare nome, descrição, source, runtime, comando de instalação e imagem de Dev Container quando aplicável.

## 3. Placeholders

Use:

~~~text
{{PROJECT_NAME}}
{{PROJECT_SLUG}}
~~~

Para renomear um arquivo com o slug:

~~~text
__PROJECT_NAME__
~~~

## 4. Nunca inclua segredos

Não coloque tokens, senhas, credenciais cloud, certificados privados ou .env real. Use .env.example.

## 5. Teste

~~~text
devkit project meu-template teste --dry-run
~~~

Depois gere em um diretório descartável.

## 6. Valide os artefatos

JSON deve ser parseável, Python deve compilar, XML deve ser válido e placeholders não podem sobrar.

## Checklist

- [ ] template mínimo;
- [ ] catálogo atualizado;
- [ ] dry-run;
- [ ] geração real em CI;
- [ ] sem placeholders restantes;
- [ ] sem segredos;
- [ ] README do template;
- [ ] Dev Container validado quando aplicável.

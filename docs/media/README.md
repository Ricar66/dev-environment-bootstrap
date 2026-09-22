# Mídia pública

Esta pasta documenta as capturas que serão usadas na divulgação do Super Dev Kit.

## Regra de segurança

Antes de publicar uma imagem ou GIF, confira se ela não mostra:

- nome de usuário pessoal desnecessário;
- hostname corporativo;
- IP interno;
- tokens;
- e-mail privado;
- caminhos com nomes de clientes;
- certificados internos;
- histórico de terminal com segredos.

## Capturas planejadas

### 1. CLI help

Comando:

~~~text
devkit help
~~~

Nome sugerido:

~~~text
cli-help.png
~~~

### 2. Dry-run de setup

~~~text
devkit setup fullstack --dry-run
~~~

Nome sugerido:

~~~text
setup-dry-run.png
~~~

### 3. Dev Doctor

~~~text
devkit doctor
~~~

Nome sugerido:

~~~text
dev-doctor.png
~~~

### 4. Project generator

~~~text
devkit project react-vite demo --dry-run
~~~

Nome sugerido:

~~~text
project-generator.png
~~~

### 5. Demo curta

Fluxo recomendado para GIF/vídeo:

~~~text
git clone ...
cd dev-environment-bootstrap
devkit.cmd version
devkit.cmd setup fullstack --dry-run
devkit.cmd doctor
~~~

No Linux, use bash devkit.sh antes de instalar o shim global.

## Tamanho

Para README, prefira largura entre 1200 e 1600 px, terminal com fonte legível e sem excesso de espaço vazio.

## Status

Os arquivos visuais devem ser capturados de uma execução real e revisados antes de entrar no README. Não use imagens geradas por IA como evidência de funcionamento da CLI.

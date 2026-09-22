# Redis com Docker Compose

Exemplo mínimo para subir um Redis local com persistência AOF.

Não há senha hardcoded neste exemplo. Ele foi pensado para desenvolvimento local e aprendizado.

## Subir

~~~bash
cd examples/redis
docker compose up -d
~~~

## Verificar

~~~bash
docker compose ps
~~~

Teste o Redis:

~~~bash
docker exec super-dev-kit-redis redis-cli ping
~~~

Saída esperada:

~~~text
PONG
~~~

## Abrir o redis-cli

~~~bash
docker exec -it super-dev-kit-redis redis-cli
~~~

Exemplo:

~~~text
SET superdevkit "ok"
GET superdevkit
~~~

## Logs

~~~bash
docker compose logs -f redis
~~~

## Parar

~~~bash
docker compose down
~~~

## Parar e remover os dados

~~~bash
docker compose down -v
~~~

Use down -v somente quando quiser apagar o volume local do Redis.

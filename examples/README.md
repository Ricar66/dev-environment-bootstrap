# Exemplos Docker

## Nginx

```bash
cd examples/nginx
docker compose up -d
```

Abra `http://localhost:8080`.

## MySQL

```bash
cd examples/mysql
cp .env.example .env
docker compose up -d
```

## PostgreSQL

```bash
cd examples/postgres
cp .env.example .env
docker compose up -d
```

## Redis

```bash
cd examples/redis
docker compose up -d
docker exec super-dev-kit-redis redis-cli ping
```

Saída esperada:

```text
PONG
```

Veja [examples/redis/README.md](redis/README.md) para os comandos de teste, logs e cleanup.

Os arquivos `.env` reais são ignorados pelo Git. Nunca publique senhas reais.

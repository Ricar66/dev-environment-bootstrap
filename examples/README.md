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

Os arquivos `.env` reais são ignorados pelo Git. Nunca publique senhas reais.

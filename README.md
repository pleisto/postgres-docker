# Postgres Docker Image with plv8 & pgvector extension

This is a Docker image for Postgres 15 with the [plv8](https://github.com/plv8/plv8) and [pgvector](https://github.com/pgvector/pgvector) extensions installed.

## Usage

```bash
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=mysecretpassword ghcr.io/pleisto/postgres-extra:latest
```

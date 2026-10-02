# Etapa 2 — Infraestrutura PostGIS

## Objetivo

Subir PostgreSQL com PostGIS via Docker Compose como banco espacial do FARISSC, com extensões vetorial e raster prontas na primeira inicialização.

## Registro incremental de passos

| Data / passo | O que foi feito | Escolha | Motivo | Referência |
|--------------|-----------------|---------|--------|------------|
| 2026-10-01 | Orquestração do banco em container | Docker Compose (serviço `db` único) | Ambiente reproduzível no monorepo, sem instalar PG no host | [Compose file reference](https://docs.docker.com/reference/compose-file/) |
| 2026-10-01 | Imagem do banco | `postgis/postgis:17-3.5` | PostgreSQL 17 + PostGIS 3.5; tag oficial atualizada em 2026-08-31 no Docker Hub | [postgis/postgis no Docker Hub](https://hub.docker.com/r/postgis/postgis/tags?name=17-3.5) |
| 2026-10-01 | Extensões na criação do banco | `postgis`, `postgis_raster` via `/docker-entrypoint-initdb.d` | Vetores (shapefile/ETL) e rasters (MDT, mapas de risco) no mesmo SGBD | [PostGIS documentation](https://postgis.net/documentation/) |
| 2026-10-01 | Persistência e segredos | Volume nomeado `pgdata`; credenciais em `.env` (modelo `.env.example`) | Dados sobrevivem ao restart; senha fora do Git | — |
| 2026-10-01 | Disponibilidade do serviço | `healthcheck` com `pg_isready` | Outros serviços (futuro ETL/API) podem esperar o banco aceitar conexões | [PostgreSQL pg_isready](https://www.postgresql.org/docs/current/app-pg-isready.html) |

## Critérios de aceite / testes

1. Copiar `.env.example` para `.env` e ajustar `POSTGRES_PASSWORD`.
2. Na raiz do monorepo: `docker compose up -d`.
3. Aguardar `healthy`: `docker compose ps`.
4. Conferir PostGIS:

```bash
docker compose exec db psql -U farissc -d farissc -c "SELECT PostGIS_Full_Version();"
docker compose exec db psql -U farissc -d farissc -c "SELECT ST_SRID(ST_SetSRID(ST_MakePoint(0, 0), 31982));"
```

Resultado esperado: extensão instalada; consulta espacial retorna SRID `31982`.

## Artefatos no repositório

- `docker-compose.yml`
- `.env.example`
- `.gitignore`
- `db/init/01-extensions.sql`

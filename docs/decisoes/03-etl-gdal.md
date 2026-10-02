# Etapa 3 — ETL (GDAL → PostGIS)

## Objetivo

Carregar os shapefiles SIGSC (já disponíveis localmente) para o schema `sc`, com registro de cada importação em `app.import_run` e `app.dataset`.

## Conjuntos esperados (mesmo prefixo de arquivo)

| layer_key | Tema SIGSC | Sidecars obrigatórios |
|-----------|------------|------------------------|
| `limites_municipios` | Limites municipais | `.shp`, `.shx`, `.dbf`, `.prj` |
| `confluencias` | Confluência (ANA) | idem |
| `cursos_dagua` | Curso d'água (ANA) | idem |
| `nascentes` | Nascente (ANA) | idem |
| `trechos_drenagem` | Trecho de drenagem (INDE) | idem |

Opcional: `.qix` (índice Esri). Não é exigido pelo GDAL.

## Registro incremental de passos

| Data / passo | O que foi feito | Escolha | Motivo | Referência |
|--------------|-----------------|---------|--------|------------|
| 2026-10-02 | Carga vetorial para PostGIS | `ogr2ogr` (GDAL) | Ferramenta padrão de interoperabilidade SIG → PostgreSQL | [ogr2ogr](https://gdal.org/programs/ogr2ogr.html) |
| 2026-10-02 | Mapeamento camada → tabela | `ingest/config/layers.yaml` | Caminhos locais configuráveis sem baixar dados no repo | — |
| 2026-10-02 | Orquestração | `ingest/Makefile` + `scripts/load-layer.sh` | Repetir carga por tema ou `make all` após ajustar paths | — |
| 2026-10-02 | Destino no banco | schema `sc`, tabela = `layer_key`, coluna `geom` | Uma tabela por tema, alinhado ao plano FARISSC | [PG driver](https://gdal.org/drivers/vector/pg.html) |
| 2026-10-02 | Geometria | `-nlt PROMOTE_TO_MULTI`, `-lco GEOMETRY_NAME=geom`, GiST | Compatibilidade PostGIS e índice espacial na carga | PostGIS docs |
| 2026-10-02 | SRID | Lido do `.prj` pelo GDAL (sem forçar na carga) | Respeita o arquivo fonte; esperado EPSG:31982 no SIGSC | [SIGSC documentação](https://sigsc.sc.gov.br/documentacao.html) |
| 2026-10-02 | Catálogo de importação | `app.import_run`, `app.dataset` em `db/init/02-schemas-etl.sql` | Rastrear origem, contagem e SRID após cada carga | — |

## Critérios de aceite / testes

1. Banco da Etapa 2 em execução (`docker compose up -d`). Se o volume foi criado antes de `02-schemas-etl.sql`, recrie o volume ou aplique o SQL manualmente.
2. Colocar shapefiles em `data/` (ou paths reais em `layers.yaml`).
3. `cd ingest && make check-ogr` (GDAL no host).
4. `cd ingest && make load-limites_municipios` (ou `make all`).
5. Conferir:

```bash
docker compose exec db psql -U farissc -d farissc -c "SELECT layer_key, feature_count, status FROM app.import_run ORDER BY id;"
docker compose exec db psql -U farissc -d farissc -c "SELECT table_name, srid FROM app.dataset;"
docker compose exec db psql -U farissc -d farissc -c "SELECT 'limites_municipios' AS t, COUNT(*) FROM sc.limites_municipios;"
```

6. Antes da carga, opcional: `ogrinfo -so -al caminho/arquivo.shp` (documentar saída em `01-fontes-dados.md`).

## Artefatos no repositório

- `db/init/02-schemas-etl.sql`
- `ingest/config/layers.yaml`
- `ingest/scripts/load-layer.sh`
- `ingest/Makefile`
- `data/.gitkeep`

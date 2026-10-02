# Decisões técnicas por etapa

Documentação incremental: a cada passo implementado, registrar escolha, motivo e referência no arquivo da etapa.

| Etapa | Arquivo | Assunto |
|-------|---------|---------|
| 1 | [01-fontes-dados.md](01-fontes-dados.md) | Fontes e CRS (conforme entram no pipeline) |
| 2 | [02-infra-postgis.md](02-infra-postgis.md) | Docker, PostgreSQL, PostGIS |
| 3 | [03-etl-gdal.md](03-etl-gdal.md) | ETL GDAL → PostGIS |
| 4 | [04-processamento-espacial.md](04-processamento-espacial.md) | Derivados espaciais / raster |
| 5 | [05-metamodelo-fuzzy.md](05-metamodelo-fuzzy.md) | Metamodelo fuzzy no banco |
| 6 | [06-motor-inferencia.md](06-motor-inferencia.md) | Motor de inferência FAM |
| 7 | [07-rastreabilidade.md](07-rastreabilidade.md) | Runs, reprodutibilidade, explain |
| 8 | [08-bff-api.md](08-bff-api.md) | BFF / API |
| 9 | [09-frontend-mapas.md](09-frontend-mapas.md) | Frontend e mapas |
| 10 | [10-validacao-resultados.md](10-validacao-resultados.md) | Validação e fatores extras |
| 11 | [11-documentacao-projeto.md](11-documentacao-projeto.md) | README, arquitetura, roteiro de demo |

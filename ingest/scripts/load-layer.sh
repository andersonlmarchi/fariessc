#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="${ROOT}/ingest/config/layers.yaml"
ENV_FILE="${ROOT}/.env"

layer_key="${1:?usage: load-layer.sh <layer_key>}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing .env (copy from .env.example)" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

shp_rel="$(grep -E "^${layer_key}:" "$CONFIG" | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
if [[ -z "$shp_rel" ]]; then
  echo "layer_key not in layers.yaml: ${layer_key}" >&2
  exit 1
fi

shp="${ROOT}/${shp_rel}"
base="${shp%.shp}"

for ext in shp shx dbf prj; do
  if [[ ! -f "${base}.${ext}" ]]; then
    echo "missing sidecar: ${base}.${ext}" >&2
    exit 1
  fi
done

table="sc.${layer_key}"
pg_conn="PG:host=127.0.0.1 port=${POSTGRES_PORT:-5432} dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}"
run_id="$(docker compose -f "${ROOT}/docker-compose.yml" exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -tA -c \
  "INSERT INTO app.import_run (layer_key, source_path, target_table, status)
   VALUES ('${layer_key}', '${shp_rel}', '${table}', 'running') RETURNING id;")"

set +e
ogr2ogr -overwrite -f PostgreSQL "$pg_conn" "$shp" \
  -nln "$table" \
  -lco GEOMETRY_NAME=geom \
  -lco SPATIAL_INDEX=GIST \
  -nlt PROMOTE_TO_MULTI
ogr_status=$?
set -e

count="$(docker compose -f "${ROOT}/docker-compose.yml" exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "SELECT COUNT(*) FROM ${table};")"
srid="$(docker compose -f "${ROOT}/docker-compose.yml" exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "SELECT ST_SRID(geom) FROM ${table} WHERE geom IS NOT NULL LIMIT 1;")"

if [[ "$ogr_status" -ne 0 ]]; then
  docker compose -f "${ROOT}/docker-compose.yml" exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -c \
    "UPDATE app.import_run SET finished_at = now(), status = 'failed', notes = 'ogr2ogr exit ${ogr_status}' WHERE id = ${run_id};"
  exit "$ogr_status"
fi

docker compose -f "${ROOT}/docker-compose.yml" exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -c "
UPDATE app.import_run
SET finished_at = now(), status = 'ok', feature_count = ${count}
WHERE id = ${run_id};

INSERT INTO app.dataset (layer_key, schema_name, table_name, srid, source_description, last_import_run_id, updated_at)
VALUES ('${layer_key}', 'sc', '${layer_key}', ${srid:-NULL}, '${shp_rel}', ${run_id}, now())
ON CONFLICT (layer_key) DO UPDATE SET
  srid = EXCLUDED.srid,
  source_description = EXCLUDED.source_description,
  last_import_run_id = EXCLUDED.last_import_run_id,
  updated_at = EXCLUDED.updated_at;
"

echo "loaded ${table}: ${count} features, SRID ${srid}"

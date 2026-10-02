CREATE SCHEMA IF NOT EXISTS sc;
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE IF NOT EXISTS app.import_run (
    id BIGSERIAL PRIMARY KEY,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at TIMESTAMPTZ,
    layer_key TEXT NOT NULL,
    source_path TEXT NOT NULL,
    target_table TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'running',
    feature_count BIGINT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS app.dataset (
    layer_key TEXT PRIMARY KEY,
    schema_name TEXT NOT NULL DEFAULT 'sc',
    table_name TEXT NOT NULL,
    srid INTEGER,
    source_description TEXT,
    last_import_run_id BIGINT REFERENCES app.import_run (id),
    updated_at TIMESTAMPTZ
);

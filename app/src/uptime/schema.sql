CREATE TABLE IF NOT EXISTS targets (
    id serial PRIMARY KEY,
    url text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS checks (
    id bigserial PRIMARY KEY,
    target_id int NOT NULL REFERENCES targets (id) ON DELETE CASCADE,
    checked_at timestamptz NOT NULL DEFAULT now(),
    up boolean NOT NULL,
    status_code int,
    duration_seconds double precision NOT NULL,
    error text
);

CREATE INDEX IF NOT EXISTS checks_target_id_checked_at ON checks (target_id, checked_at DESC);

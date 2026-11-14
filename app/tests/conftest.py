import os

import psycopg
import pytest

from uptime import migrate

os.environ.setdefault("PGHOST", "localhost")
os.environ.setdefault("PGUSER", "uptime")
os.environ.setdefault("PGPASSWORD", "uptime")
os.environ.setdefault("PGDATABASE", "uptime_test")


@pytest.fixture
def db():
    with psycopg.connect(autocommit=True) as conn:
        conn.execute("DROP TABLE IF EXISTS checks, targets")
        migrate.main()
        yield conn

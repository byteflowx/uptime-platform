from pathlib import Path

import psycopg


def main() -> None:
    with psycopg.connect(autocommit=True) as conn:
        conn.execute(Path(__file__).with_name("schema.sql").read_text())


if __name__ == "__main__":
    main()

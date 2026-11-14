import psycopg
from psycopg.rows import dict_row


async def connect() -> psycopg.AsyncConnection:
    return await psycopg.AsyncConnection.connect(row_factory=dict_row)

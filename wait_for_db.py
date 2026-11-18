"""Aguarda o PostgreSQL aceitar conexões antes de iniciar a aplicação.

Substitui o `pg_isready` (pacote de sistema postgresql-client) usando o
psycopg2, que já é dependência da aplicação.

Diferente do pg_isready, aqui é feita uma conexão real, então as
credenciais também são validadas. Se o banco não ficar disponível dentro
de DB_WAIT_TIMEOUT segundos (padrão: 60), o script sai com erro em vez de
esperar para sempre.
"""

import os
import sys
import time

import psycopg2

timeout = int(os.getenv("DB_WAIT_TIMEOUT", "60"))
deadline = time.monotonic() + timeout

while True:
    try:
        psycopg2.connect(
            host=os.environ["DB_HOST"],
            port=os.getenv("DB_PORT", "5432"),
            dbname=os.environ["DB_NAME"],
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            connect_timeout=3,
        ).close()
        break
    except psycopg2.OperationalError as e:
        if time.monotonic() > deadline:
            print(f"Banco de dados indisponível após {timeout}s: {e}", file=sys.stderr)
            sys.exit(1)
        print("Banco de dados indisponível - aguardando...")
        time.sleep(1)

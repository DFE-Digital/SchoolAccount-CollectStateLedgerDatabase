#!/bin/bash
# Waits for SQL Server to accept connections, then applies the CollectStateLedger
# scripts in order. This is the only place that knows what they are called and what
# order they go in.
set -euo pipefail

readonly SERVER="${MSSQL_SERVER:-host.docker.internal}"
readonly USERNAME="${MSSQL_USER:-sa}"
readonly SQL_DIR="${SQL_DIR:-/sql}"
readonly WAIT_SECONDS="${MSSQL_WAIT_SECONDS:-60}"
readonly SCRIPTS=(database tables stored-procedures)

if [[ -z "${MSSQL_PASSWORD:-}" ]]; then
    echo "MSSQL_PASSWORD is not set" >&2
    exit 1
fi

# tools18 ships in the server image, tools in the mssql-tools image.
SQLCMD=
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
    if [[ -x "$candidate" ]]; then
        SQLCMD="$candidate"
        break
    fi
done

if [[ -z "$SQLCMD" ]]; then
    echo "No sqlcmd found" >&2
    exit 1
fi

echo "Waiting for SQL Server on ${SERVER}..."
ready=false
for (( second = 0; second < WAIT_SECONDS; second++ )); do
    if "$SQLCMD" -C -t 1 -S "$SERVER" -U "$USERNAME" -P "$MSSQL_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 1
done

if [[ "$ready" != true ]]; then
    echo "SQL Server on ${SERVER} did not become available within ${WAIT_SECONDS}s" >&2
    exit 1
fi

for script in "${SCRIPTS[@]}"; do
    echo "Applying ${script}.sql"
    "$SQLCMD" -C -b -S "$SERVER" -U "$USERNAME" -P "$MSSQL_PASSWORD" -d master -i "${SQL_DIR}/${script}.sql"
done

echo "Schema applied."

#!/bin/bash
# Starts SQL Server, applies the CollectStateLedger schema, then stays in the foreground.
# The health check only passes once /tmp/schema-applied exists, so anything waiting on the
# container gets a database with the tables already in it.
set -euo pipefail

readonly SQLCMD=/opt/mssql-tools18/bin/sqlcmd
readonly READY_FILE=/tmp/schema-applied
readonly SCRIPTS=(database tables stored-procedures)
readonly WAIT_SECONDS="${SCHEMA_WAIT_SECONDS:-180}"

if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
    echo "MSSQL_SA_PASSWORD is not set" >&2
    exit 1
fi

/opt/mssql/bin/sqlservr &
readonly SQLSERVR_PID=$!

trap 'kill -TERM "$SQLSERVR_PID" 2>/dev/null || true' TERM INT

echo "Waiting for SQL Server to accept connections..."
ready=false
for (( second = 0; second < WAIT_SECONDS; second++ )); do
    if ! kill -0 "$SQLSERVR_PID" 2>/dev/null; then
        echo "SQL Server exited before it became available" >&2
        wait "$SQLSERVR_PID"
        exit 1
    fi
    if "$SQLCMD" -C -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 1
done

if [[ "$ready" != true ]]; then
    echo "SQL Server did not become available within ${WAIT_SECONDS}s" >&2
    exit 1
fi

for script in "${SCRIPTS[@]}"; do
    echo "Applying ${script}.sql"
    "$SQLCMD" -C -b -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -d master -i "/schema/sql/${script}.sql"
done

touch "$READY_FILE"
echo "Schema applied."

wait "$SQLSERVR_PID"

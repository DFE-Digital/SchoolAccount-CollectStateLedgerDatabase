#!/bin/bash
# Container entrypoint. Starts SQL Server, applies the schema, then stays in the foreground.
# The health check only passes once the marker file exists, so anything waiting on the
# container gets a database with the tables already in it.
set -euo pipefail

readonly READY_FILE=/tmp/schema-applied

if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
    echo "MSSQL_SA_PASSWORD is not set" >&2
    exit 1
fi

/opt/mssql/bin/sqlservr &
readonly SQLSERVR_PID=$!

trap 'kill -TERM "$SQLSERVR_PID" 2>/dev/null || true' TERM INT

MSSQL_SERVER=localhost \
MSSQL_USER=sa \
MSSQL_PASSWORD="$MSSQL_SA_PASSWORD" \
SQL_DIR=/schema/sql \
MSSQL_WAIT_SECONDS="${SCHEMA_WAIT_SECONDS:-180}" \
    /schema/scripts/configure-db.sh

touch "$READY_FILE"

wait "$SQLSERVR_PID"

#!/bin/bash

TRIES=60
DB_STATUS=1
i=0

while [[ $DB_STATUS -ne 0 ]] && [[ $i -lt $TRIES ]]; do
	i=$((i+1))
	DB_STATUS=$(/opt/mssql-tools/bin/sqlcmd -h -1 -t 1 -S host.docker.internal -U "$MSSQL_USER" -P "$MSSQL_PASSWORD" -C -Q "SET NOCOUNT ON; Select COALESCE(SUM(state), 0) from sys.databases") || DB_STATUS=1
	echo "Waiting for database to be ready..."
	sleep 1s
done

if [[ $DB_STATUS -ne 0 ]]; then 
	echo "SQL Server took more than $TRIES seconds to start up or one or more databases are not in an ONLINE state"
	exit 1
fi

# Run the setup script to create the DB and the schema in the DB
echo "Running configuration script..."


/opt/mssql-tools/bin/sqlcmd -S host.docker.internal -U "$MSSQL_USER" -P "$MSSQL_PASSWORD" -C -d master -i /sql/database.sql
/opt/mssql-tools/bin/sqlcmd -S host.docker.internal -U "$MSSQL_USER" -P "$MSSQL_PASSWORD" -C -d master -i /sql/tables.sql
/opt/mssql-tools/bin/sqlcmd -S host.docker.internal -U "$MSSQL_USER" -P "$MSSQL_PASSWORD" -C -d master -i /sql/stored-procedures.sql

echo "Configuration completed."
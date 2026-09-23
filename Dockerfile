FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

COPY sql/ /schema/sql/
COPY docker/apply-schema.sh /schema/apply-schema.sh

RUN chmod +x /schema/apply-schema.sh && chown -R mssql:root /schema

USER mssql

# MSSQL_SA_PASSWORD is deliberately not defaulted here: the image is public and the
# entrypoint fails with a clear message when it is missing.
ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer

EXPOSE 1433

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=30 \
    CMD /bin/bash -c '[ -f /tmp/schema-applied ] && /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -d CollectStateLedger -Q "SELECT 1" > /dev/null'

ENTRYPOINT ["/schema/apply-schema.sh"]

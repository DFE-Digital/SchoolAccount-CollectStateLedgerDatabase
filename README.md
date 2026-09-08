# SchoolAccount-CollectStateLedgerDatabase

This repository contains migration scripts and a stored procedure to track COLLECT data return status changes in the `CollectStateLedger` database.

# Database and Schema

The database `CollectStateLedger` should be available alongside the `COLLECTPortal` database in iStore.

For working locally a [sql/database.sql](./sql/database.sql) script is available to create a suitable database. Note that the script sets the database collation as `Latin1_General_CI_AS` to ensure cross database joins are using the same character set.

A SQL script [sql/tables](./sql/tables.sql) is provided to create the table required by the stored procedure to track changes.
[sql/stored-procedures](./sql/stored-procedures.sql) creates the stored procedure itself.

The table `CollectReturnStatus` follows the existing COLLECT database conventions and contains only information that can be obtained directly from the iStore `COLLECTPortal` database:


| Column Name.     | Type          | Description                   |
|------------------|---------------|-------------------------------|
| Id               | int           | Auto-incrementing primary key |
| SchoolName       | nvarchar(250) | Name of school                |
| LAEStab          | nvarchar(50)  | LAEStab of the organisation   |
| ReturnStatus     | int           | Status of the data return     |
| Errors           | int           | Number of errors on return    |
| Queries          | int           | Number of queries on return   |
| OkdErrorsQueries | int           | Number of resolved issues     |
| Hash             | nvarchar(36)  | Hash of status and counts     |
| UpdatedAt        | datetime      | Time and date row was written |
| DCID             | int           | DataCollection ID             |
| Collection       | nvarchar(128) | DataCollection database name  |
| DataReturnId     | int           | ID of DataReturn row          |


The organisation is identified by the `LAEStab`, as the `UKPRN` is not available within the COLLECT Portal.

The `Hash` is used to compare current and previous state in the stored procedure.

The Portal convention of using an identity primary key is used in preference to a [SEQUENCE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-sequence-transact-sql?view=sql-server-ver17).

Although only the `LAEStab`, `ReturnStatus`, `DCID`, `Errors`, `Queries`, `OKdErrorsQueries`, `Hash`, and `UpdatedAt` are essential for tracking state, other columns are provided to simplify use by the consuming service.

At present there are no additional indexes on the table to improve performance.

The following SQL demonstrates running the stored procedure `AddChangedCollectReturnStatus` against the `SchoolCensus2025_Spring` collection:
```sql
DECLARE @RC int 
EXECUTE @RC = [dbo].[AddChangedCollectReturnStatus] 'SchoolCensus2025_Spring'
```
When running locally this updates 22,000 rows in 0.35 seconds.

# Local development
A [docker compose](./docker-compose.yml) file is provided to run the migrations against a local database. The scripts assumes the database is running on the standard SQL server port of `1433`.

The default SQL user and password are set to the standard School Account development SQL credentials. These may be overridden by adding a `.env` file to the project root with the following contents, substituting `db-user` and `my-db-password` with the required values:
```
MSSQL_USER=my-db-user
MSSQL_PASSWORD=my-db-password
```

Executing the following command from the project root will run the migration:
```
docker compose up
```

# Further Information

A [SchoolAccount-LocalDevTools](https://github.com/DFE-Digital/SchoolAccount-LocalDevTools) project is available that allows a developer to run a local copy of the `COLLECTPortal` database from a backup.

The stored procedure has been thoroughly tested using the above by simulating updates in a local copy of the database and verifying changes are detected.

The following SQL may be used to manually update a row in the Portal Database for testing purposes.

 This example updates the status and counts for LAEstab `8162009` and collection `SchoolCensus2025_Spring`.

```sql
DECLARE @LAEStab [nvarchar] (50) = '8612009'
DECLARE @CensusName [nvarchar] (128) = 'SchoolCensus2025_Spring'
DECLARE @Status [int] = 7
DECLARE @HighErrors [int] = 4
DECLARE @LowErrors [int] = 5
DECLARE @OKErrors [int] = 6
    
UPDATE dr
SET 
  DRStatus = @Status, 
  HighErrors = @HighErrors,
  LowErrors = @LowErrors,
  OKErrors = @OKErrors
FROM COLLECTPortal.dbo.DataReturn dr
INNER JOIN COLLECTPortal.dbo.OrganisationRole orol
    ON dr.SourceOrganisationRoleID = orol.OrganisationRoleID
INNER JOIN COLLECTPortal.dbo.Organisation o
    ON orol.OrganisationID = o.OrganisationID
INNER JOIN CollectPortal.dbo.OrganisationRole orol2
    ON dr.AgentOrganisationRoleID = orol2.OrganisationRoleID
INNER JOIN COLLECTPortal.dbo.Organisation o2
    ON orol2.OrganisationID = o2.OrganisationID
INNER JOIN COLLECTPortal.dbo.DataCollection dc
    ON dc.DCID = dr.DCID
WHERE o.OrganisationNativeID = @Laestab
AND dc.DCBladeSQLDatabase = @CensusName
```

The following query will return the current and previous status for a particular LAEStab and Collection:
```sql
DECLARE @LAEStab [nvarchar] (50) = '8612009'
DECLARE @CensusName [nvarchar] (128) = 'SchoolCensus2025_Spring'
    
SELECT [SchoolName]
      ,[LAEStab]
      ,[ReturnStatusCode]
      ,LAG([ReturnStatusCode]) OVER (ORDER BY [UpdatedAt] ASC) AS [PreviousReturnStatusCode]
      ,[Errors]
      ,[Queries]
      ,[OkdErrorsQueries]
      ,[Hash]
      ,[UpdatedAt]
      ,[Collection]
      ,[DCID]
  FROM [CollectStateLedger].[dbo].[CollectReturnStatus]
where LAEStab = @LAEStab and [Collection] = @CensusName
```
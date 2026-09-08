USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'CollectStateLedger')
    BEGIN
        CREATE DATABASE [CollectStateLedger];
        ALTER DATABASE CollectStateLedger COLLATE Latin1_General_CI_AS;
    END
GO

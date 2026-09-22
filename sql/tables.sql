IF OBJECT_ID('CollectStateLedger.dbo.CollectReturnStatus', 'U') IS NULL
BEGIN
CREATE TABLE  CollectStateLedger.dbo.CollectReturnStatus
(
    [Id]                    [int] IDENTITY(1,1) PRIMARY KEY,
    [SchoolName]            [nvarchar] (250)  NOT NULL,
    [LAEStab]               [nvarchar] (50)   NOT NULL,
    [ReturnStatusCode]      [int] NOT NULL,
    [Errors]                [int] NULL,
    [Queries]               [int] NULL,
    [OkdErrorsQueries]      [int] NULL,
    [Hash]                  [nvarchar] (36)   NOT NULL,
    [UpdatedAt]             [datetime]        NOT NULL,
    [DCID]                  [int]             NOT NULL,
    [Collection]            [nvarchar] (128)  NOT NULL,
    [DataReturnID]          [int] NOT NULL
);

END

GO

IF OBJECT_ID('CollectStateLedger.dbo.RegisteredUsers', 'U') IS NULL
BEGIN
CREATE TABLE  CollectStateLedger.dbo.RegisteredUsers
(
    [Id]                    [int] IDENTITY(1,1) PRIMARY KEY,
    [LAEStab]               [nvarchar] (50) NOT NULL,
    [Email]                 [nvarchar] (250) NOT NULL
);
END

GO

IF OBJECT_ID('CollectStateLedger.dbo.JobStatus', 'U') IS NULL
BEGIN
CREATE TABLE  CollectStateLedger.dbo.JobStatus
(
    [Id]                    [int] IDENTITY(1,1) PRIMARY KEY,
    [Name]                  [nvarchar] (50) NOT NULL,
    [LastRun]               [datetime]  NULL
);
END

GO

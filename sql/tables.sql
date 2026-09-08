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

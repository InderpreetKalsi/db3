CREATE TABLE [dbo].[mpDataSyncSupplierProfileToCommunityLogs] (
    [Id]                    INT           IDENTITY (1, 1) NOT NULL,
    [DBObject]              VARCHAR (250) NOT NULL,
    [CompanyId]             INT           NOT NULL,
    [CreatedOn]             DATETIME      DEFAULT (getutcdate()) NULL,
    [IsProcessed]           BIT           DEFAULT ((0)) NULL,
    [FetchDataFromDateTime] DATETIME      NOT NULL,
    [FetchDataToDateTime]   DATETIME      NULL,
    [CompanyProfileStatus]  SMALLINT      NULL,
    [IsSyncFailed]          BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [PK_mpDataSyncSupplierProfileToCommunityLogs_Id_CreatedOn] PRIMARY KEY CLUSTERED ([Id] ASC, [FetchDataFromDateTime] ASC, [CompanyId] ASC) WITH (FILLFACTOR = 90)
);


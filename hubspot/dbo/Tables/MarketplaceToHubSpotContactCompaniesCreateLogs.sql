CREATE TABLE [dbo].[MarketplaceToHubSpotContactCompaniesCreateLogs] (
    [Id]                INT           IDENTITY (1000, 1) NOT NULL,
    [Vision Account Id] INT           NULL,
    [Vision Contact Id] INT           NULL,
    [SyncType]          VARCHAR (100) NULL,
    [IsSynced]          BIT           DEFAULT ((0)) NULL,
    [SyncedDate]        DATETIME      NULL,
    [SyncedDateIST]     DATETIME      NULL,
    [IsProcessed]       BIT           DEFAULT (NULL) NULL,
    [ProcessedDate]     DATETIME      NULL,
    [ProcessedDateIST]  DATETIME      NULL,
    CONSTRAINT [Pk_MarketplaceToHubSpotContactCompaniesCreateLogs_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MarketplaceToHubSpotContactCompaniesCreateLogs_VisionAccountId]
    ON [dbo].[MarketplaceToHubSpotContactCompaniesCreateLogs]([Vision Account Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MarketplaceToHubSpotContactCompaniesCreateLogs_VisionContactId]
    ON [dbo].[MarketplaceToHubSpotContactCompaniesCreateLogs]([Vision Contact Id] ASC);


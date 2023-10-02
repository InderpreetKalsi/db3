CREATE TABLE [dbo].[MarketplaceToHubSpotContactCompaniesLogs] (
    [Id]                INT      IDENTITY (1000, 1) NOT NULL,
    [Vision Account Id] INT      NULL,
    [Vision Contact Id] INT      NULL,
    [IsSynced]          BIT      DEFAULT ((0)) NULL,
    [SyncedDate]        DATETIME NULL,
    [SyncedDateIST]     DATETIME NULL,
    [IsProcessed]       BIT      DEFAULT (NULL) NULL,
    [ProcessedDate]     DATETIME NULL,
    [ProcessedDateIST]  DATETIME NULL,
    CONSTRAINT [Pk_MarketplaceToHubSpotContactCompaniesLogs_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MarketplaceToHubSpotContactCompaniesLogs_Email_VisionAccountId]
    ON [dbo].[MarketplaceToHubSpotContactCompaniesLogs]([Vision Account Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MarketplaceToHubSpotContactCompaniesLogs_Email_VisionContactId]
    ON [dbo].[MarketplaceToHubSpotContactCompaniesLogs]([Vision Contact Id] ASC);


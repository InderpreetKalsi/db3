CREATE TABLE [dbo].[mpSavedSearchEmailLogs] (
    [Id]            INT      IDENTITY (1, 1) NOT NULL,
    [ContactId]     INT      NULL,
    [SavedSearchId] INT      NULL,
    [RfqId]         INT      NULL,
    [LogDate]       DATETIME DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [NC_mpSavedSearchEmailLogs_ContactId_SavedSearchId]
    ON [dbo].[mpSavedSearchEmailLogs]([ContactId] ASC, [SavedSearchId] ASC) WITH (FILLFACTOR = 90);


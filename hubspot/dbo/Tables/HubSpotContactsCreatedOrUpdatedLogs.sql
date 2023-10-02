CREATE TABLE [dbo].[HubSpotContactsCreatedOrUpdatedLogs] (
    [ID]                           INT           IDENTITY (1, 1) NOT NULL,
    [HubSpotContactsIdentityKeyId] INT           NULL,
    [HubSpotContactId]             VARCHAR (255) NULL,
    [IsProcessed]                  BIT           NULL,
    [IsSynced]                     BIT           NULL,
    [ProcessedDate]                DATETIME      NULL,
    [SyncedDate]                   DATETIME      NULL,
    [CreatedDate]                  DATETIME      DEFAULT (getutcdate()) NULL,
    [TransactionStatus]            INT           DEFAULT ((0)) NULL,
    [ErrorMessages]                VARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


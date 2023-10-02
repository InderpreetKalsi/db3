CREATE TABLE [dbo].[HubSpotContactsDownSyncLogs] (
    [Id]                INT           IDENTITY (1, 1) NOT NULL,
    [Vision Contact Id] INT           NULL,
    [First Name]        VARCHAR (255) NULL,
    [Last Name]         VARCHAR (255) NULL,
    [Email Opt Out]     BIT           NULL,
    [SyncedDate]        DATETIME      DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


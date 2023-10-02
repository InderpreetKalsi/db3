CREATE TABLE [dbo].[HubSpotCompaniesDownSyncLogs] (
    [Id]                         INT           IDENTITY (1, 1) NOT NULL,
    [Vision Account Id]          INT           NULL,
    [Hide Directory Profile]     BIT           NULL,
    [Manufacturing Location]     VARCHAR (100) NULL,
    [Company Owner Id]           INT           NULL,
    [Account Paid Status]        VARCHAR (100) NULL,
    [SyncedDate]                 DATETIME      DEFAULT (getutcdate()) NULL,
    [IsEligibleForGrowthPackage] BIT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


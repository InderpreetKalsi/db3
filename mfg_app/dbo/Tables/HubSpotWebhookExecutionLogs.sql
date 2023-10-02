CREATE TABLE [dbo].[HubSpotWebhookExecutionLogs] (
    [LogID]                      INT           IDENTITY (1, 1) NOT NULL,
    [CompanyID]                  INT           NULL,
    [HubSpotAccountId]           VARCHAR (200) NULL,
    [IsEligibleForGrowthPackage] BIT           NULL,
    [LogDateTime]                DATETIME      DEFAULT (getutcdate()) NULL,
    [WebhookType]                VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([LogID] ASC)
);


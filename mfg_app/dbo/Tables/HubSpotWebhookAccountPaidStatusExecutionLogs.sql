CREATE TABLE [dbo].[HubSpotWebhookAccountPaidStatusExecutionLogs] (
    [LogID]             INT           IDENTITY (1, 1) NOT NULL,
    [CompanyID]         INT           NULL,
    [HubSpotAccountId]  VARCHAR (200) NULL,
    [AccountPaidStatus] VARCHAR (100) NULL,
    [WebhookType]       VARCHAR (100) NULL,
    [LogDateTime]       DATETIME      DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([LogID] ASC)
);


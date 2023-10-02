CREATE TABLE [dbo].[HubSpotWebhookCompanyQuotingCapabilityExecutionLogs] (
    [LogID]                    INT           IDENTITY (1, 1) NOT NULL,
    [CompanyID]                INT           NULL,
    [HubSpotAccountId]         VARCHAR (200) NULL,
    [HubSpotQuotingCapability] VARCHAR (MAX) NULL,
    [LogDateTime]              DATETIME      DEFAULT (getutcdate()) NULL,
    [WebhookType]              VARCHAR (100) NULL,
    [AccountType]              INT           NULL,
    PRIMARY KEY CLUSTERED ([LogID] ASC)
);


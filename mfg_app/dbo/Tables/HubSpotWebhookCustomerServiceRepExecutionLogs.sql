CREATE TABLE [dbo].[HubSpotWebhookCustomerServiceRepExecutionLogs] (
    [LogID]                               INT           IDENTITY (1, 1) NOT NULL,
    [CompanyID]                           INT           NULL,
    [HubSpotAccountId]                    VARCHAR (200) NULL,
    [HubSpotUserId]                       VARCHAR (200) NULL,
    [LogDateTime]                         DATETIME      DEFAULT (getutcdate()) NULL,
    [WebhookType]                         VARCHAR (100) NULL,
    [PreviousCustomerServiceRepContactId] INT           NULL,
    PRIMARY KEY CLUSTERED ([LogID] ASC)
);


CREATE TABLE [dbo].[mpGatewayWebhookLogs] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [ContactId]       INT            NULL,
    [Email]           VARCHAR (250)  NULL,
    [WebhookResponse] VARCHAR (8000) NULL
);


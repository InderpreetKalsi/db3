CREATE TABLE [dbo].[HubSpotUpSyncAPIRequestResponseLogs] (
    [Id]                           INT            IDENTITY (1, 1) NOT NULL,
    [HubSpotModuleType]            VARCHAR (100)  NULL,
    [OperationType]                VARCHAR (100)  NULL,
    [Email]                        NVARCHAR (500) NULL,
    [VisionAccountId]              INT            NULL,
    [RfqId]                        INT            NULL,
    [HubSpotAPIRequestURL]         NVARCHAR (MAX) NULL,
    [HubSpotAPIRequestJSON]        NVARCHAR (MAX) NULL,
    [HubSpotAPIResponseJSON]       NVARCHAR (MAX) NULL,
    [HubSpotAPIResponseStatusCode] VARCHAR (100)  NULL,
    [CreateDate]                   DATETIME       DEFAULT (getutcdate()) NULL,
    [IsSuccess]                    BIT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


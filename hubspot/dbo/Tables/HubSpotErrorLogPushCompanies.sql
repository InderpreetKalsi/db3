CREATE TABLE [dbo].[HubSpotErrorLogPushCompanies] (
    [Id]                INT            IDENTITY (100, 1) NOT NULL,
    [PushType]          VARCHAR (50)   NULL,
    [Vision Company Id] INT            NULL,
    [Error]             VARCHAR (2000) NULL,
    [ErrorDate]         DATETIME       DEFAULT (getutcdate()) NULL,
    CONSTRAINT [Pk_HubSpotErrorLogPushCompanies_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotErrorLogPushCompanies_Vision_Company_Id]
    ON [dbo].[HubSpotErrorLogPushCompanies]([Vision Company Id] ASC, [PushType] ASC);


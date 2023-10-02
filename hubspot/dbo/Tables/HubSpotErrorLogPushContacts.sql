CREATE TABLE [dbo].[HubSpotErrorLogPushContacts] (
    [Id]                INT            IDENTITY (100, 1) NOT NULL,
    [PushType]          VARCHAR (50)   NULL,
    [Vision Contact Id] INT            NULL,
    [Error]             VARCHAR (2000) NULL,
    [ErrorDate]         DATETIME       DEFAULT (getutcdate()) NULL,
    CONSTRAINT [Pk_HubSpotErrorLogPushContacts_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotErrorLogPushContacts_Vision_Contact_Id]
    ON [dbo].[HubSpotErrorLogPushContacts]([Vision Contact Id] ASC, [PushType] ASC);


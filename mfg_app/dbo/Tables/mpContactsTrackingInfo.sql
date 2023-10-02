CREATE TABLE [dbo].[mpContactsTrackingInfo] (
    [Id]               INT            IDENTITY (1, 1) NOT NULL,
    [FirstName]        NVARCHAR (100) NULL,
    [LastName]         NVARCHAR (100) NULL,
    [Email]            NVARCHAR (256) NULL,
    [PhoneNo]          VARCHAR (100)  NULL,
    [FormType]         VARCHAR (100)  NULL,
    [HubSpotContactId] VARCHAR (255)  NULL,
    [TrackingDate]     DATETIME       DEFAULT (getutcdate()) NULL,
    [IPAddress]        VARCHAR (100)  NULL,
    [PageName]         VARCHAR (200)  NULL,
    [PageURI]          VARCHAR (MAX)  NULL,
    [Hutk]             VARCHAR (200)  NULL,
    [FormGuid]         VARCHAR (200)  NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


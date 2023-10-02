CREATE TABLE [dbo].[HubSpotContactsOneTimePull] (
    [Id]                INT           IDENTITY (100, 1) NOT NULL,
    [Email]             VARCHAR (500) NULL,
    [HubSpot ContactId] VARCHAR (255) NULL,
    CONSTRAINT [Pk_HubSpotContactsOneTimePull_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


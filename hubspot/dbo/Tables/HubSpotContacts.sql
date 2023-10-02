CREATE TABLE [dbo].[HubSpotContacts] (
    [Id]                                INT           IDENTITY (1000, 1) NOT NULL,
    [Email]                             VARCHAR (255) NULL,
    [HubSpot Contact Id]                VARCHAR (255) NULL,
    [Contact Id]                        VARCHAR (255) NULL,
    [Vision Buyer Id]                   INT           NULL,
    [Vision Buyer Account Id]           INT           NULL,
    [HubSpot Buyer Account Id]          VARCHAR (255) NULL,
    [Vision Supplier Id]                INT           NULL,
    [Vision Supplier Account Id]        INT           NULL,
    [HubSpot Supplier Account Id]       VARCHAR (255) NULL,
    [Buyer City]                        VARCHAR (255) NULL,
    [Buyer Country]                     VARCHAR (255) NULL,
    [Buyer First Name]                  VARCHAR (255) NULL,
    [Buyer Last Name]                   VARCHAR (255) NULL,
    [Buyer Phone]                       VARCHAR (255) NULL,
    [Buyer Postal Code]                 VARCHAR (255) NULL,
    [Buyer State]                       VARCHAR (255) NULL,
    [Buyer Street Address]              VARCHAR (255) NULL,
    [Buyer Street Address 2]            VARCHAR (255) NULL,
    [Buyer Territory]                   VARCHAR (255) NULL,
    [City]                              VARCHAR (255) NULL,
    [Country]                           VARCHAR (255) NULL,
    [Country/Region]                    VARCHAR (255) NULL,
    [Fax]                               VARCHAR (255) NULL,
    [First Name]                        VARCHAR (255) NULL,
    [First RFQ Release Date]            DATETIME      NULL,
    [Industry]                          VARCHAR (255) NULL,
    [Last Name]                         VARCHAR (255) NULL,
    [Last Upgrade Request Date]         DATETIME      NULL,
    [MFG Contact Type]                  VARCHAR (255) NULL,
    [Mobile Phone]                      VARCHAR (255) NULL,
    [Most Recent RFQ Release Date]      DATETIME      NULL,
    [Number of RFQs]                    INT           NULL,
    [Phone]                             VARCHAR (255) NULL,
    [Postal Code]                       VARCHAR (255) NULL,
    [State/Region]                      VARCHAR (255) NULL,
    [Street Address]                    VARCHAR (255) NULL,
    [Territory]                         VARCHAR (255) NULL,
    [Unsubscribed from all email]       BIT           NULL,
    [Upgrade Request]                   BIT           NULL,
    [Vision RFQ Validated]              BIT           NULL,
    [Website URL]                       VARCHAR (255) NULL,
    [IsSynced]                          BIT           DEFAULT ((0)) NULL,
    [SyncedDate]                        DATETIME      NULL,
    [SyncedDateIST]                     DATETIME      NULL,
    [IsProcessed]                       BIT           DEFAULT (NULL) NULL,
    [ProcessedDate]                     DATETIME      NULL,
    [ProcessedDateIST]                  DATETIME      NULL,
    [SyncType]                          TINYINT       NULL,
    [Terms and Conditions Action Date]  DATETIME      NULL,
    [Terms and Conditions Status]       VARCHAR (50)  NULL,
    [Terms and Conditions Contact Type] VARCHAR (50)  NULL,
    [Registration Date]                 DATETIME      NULL,
    [Vision Validated Date]             DATETIME      NULL,
    [Buyer Registration Date]           DATETIME      NULL,
    [Is Test Contact]                   BIT           NULL,
    CONSTRAINT [Pk_HubSpotContacts_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotContacts_Email]
    ON [dbo].[HubSpotContacts]([Email] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotContacts_Vision_Buyer_Id]
    ON [dbo].[HubSpotContacts]([Vision Buyer Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotContacts_Vision_Supplier_Id]
    ON [dbo].[HubSpotContacts]([Vision Supplier Id] ASC);


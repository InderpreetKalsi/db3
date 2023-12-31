﻿CREATE TABLE [dbo].[HubSpotRFQs] (
    [Id]                     INT            IDENTITY (1, 1) NOT NULL,
    [Rfq Number]             VARCHAR (255)  NULL,
    [Rfq Name]               NVARCHAR (MAX) NULL,
    [Rfq Description]        NVARCHAR (MAX) NULL,
    [Vision Link]            VARCHAR (100)  NULL,
    [MFG Legacy Rfq Id]      INT            NULL,
    [Modified Date]          DATETIME       NULL,
    [Created Date]           DATETIME       NULL,
    [SyncType]               TINYINT        NULL,
    [IsSynced]               BIT            NULL,
    [Buyer Id]               BIGINT         NULL,
    [Buyer Name]             NVARCHAR (MAX) NULL,
    [Rfq Close Date]         DATETIME       NULL,
    [MFG Discipline]         NVARCHAR (MAX) NULL,
    [MFG 2nd Discipline]     NVARCHAR (MAX) NULL,
    [Assigned Engineer]      NVARCHAR (MAX) NULL,
    [RFQ Status]             INT            NULL,
    [Rfq Release Date]       DATETIME       NULL,
    [Part Count]             INT            NULL,
    [Region]                 INT            NULL,
    [Number Of Quotes]       INT            NULL,
    [Quote Summary Link]     NVARCHAR (MAX) NULL,
    [IsDeleted]              BIT            NULL,
    [MFG 1st Discipline]     NVARCHAR (MAX) NULL,
    [Rfq Buyer Status Id]    INT            NULL,
    [Rfq User Status Id]     INT            NULL,
    [IsProcessed]            BIT            NULL,
    [SyncedDate]             DATETIME       NULL,
    [ProcessedDate]          DATETIME       NULL,
    [Rfq Materials]          VARCHAR (2000) NULL,
    [Is Mfg Community Rfq]   BIT            NULL,
    [HubSpot Rfq Id]         VARCHAR (255)  NULL,
    [Rfq Quote Link]         VARCHAR (2000) NULL,
    [Rfq Reshape Order Link] NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_HubSpotRFQs] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 80)
);


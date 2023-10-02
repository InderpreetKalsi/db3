﻿CREATE TABLE [dbo].[bk_hubspotcompanies_16_may_2023] (
    [Id]                             INT            IDENTITY (1000, 1) NOT NULL,
    [Vision Account Id]              INT            NULL,
    [HubSpot Account Id]             VARCHAR (255)  NULL,
    [IsBuyerAccount]                 BIT            NULL,
    [Account Paid Status]            VARCHAR (255)  NULL,
    [Buyer Company City]             VARCHAR (255)  NULL,
    [Buyer Company Country]          VARCHAR (255)  NULL,
    [Buyer Company Phone]            VARCHAR (255)  NULL,
    [Buyer Company Postal Code]      VARCHAR (255)  NULL,
    [Buyer Company State]            VARCHAR (255)  NULL,
    [Buyer Company Street Address]   VARCHAR (255)  NULL,
    [Buyer Company Street Address 2] VARCHAR (255)  NULL,
    [Cage Code]                      VARCHAR (255)  NULL,
    [City]                           VARCHAR (255)  NULL,
    [Company Name]                   VARCHAR (255)  NULL,
    [Company Owner Id]               INT            NULL,
    [Country/Region]                 VARCHAR (255)  NULL,
    [Create Date]                    DATETIME       NULL,
    [Customer Service Rep Id]        INT            NULL,
    [Discipline Level 0]             VARCHAR (2000) NULL,
    [Discipline Level 1]             VARCHAR (2000) NULL,
    [Duns Number]                    VARCHAR (255)  NULL,
    [Facebook Company Page]          VARCHAR (255)  NULL,
    [Google Plus Page]               VARCHAR (255)  NULL,
    [Hide Directory Profile]         BIT            NULL,
    [Industry]                       VARCHAR (1000) NULL,
    [LinkedIn Company Page]          VARCHAR (255)  NULL,
    [Number of Employees]            INT            NULL,
    [Phone Number]                   VARCHAR (255)  NULL,
    [Postal Code]                    VARCHAR (255)  NULL,
    [Public Profile URL]             VARCHAR (1000) NULL,
    [RFQ Access Capabilities 0]      VARCHAR (2000) NULL,
    [RFQ Access Capabilities 1]      VARCHAR (2000) NULL,
    [State/Region]                   VARCHAR (255)  NULL,
    [Street Address]                 VARCHAR (255)  NULL,
    [Street Address 2]               VARCHAR (255)  NULL,
    [Manufacturing Location]         VARCHAR (100)  NULL,
    [Twitter Handle]                 VARCHAR (255)  NULL,
    [IsSynced]                       BIT            NULL,
    [SyncedDate]                     DATETIME       NULL,
    [SyncedDateIST]                  DATETIME       NULL,
    [IsProcessed]                    BIT            NULL,
    [ProcessedDate]                  DATETIME       NULL,
    [ProcessedDateIST]               DATETIME       NULL,
    [SyncType]                       TINYINT        NULL,
    [IsEligibleForGrowthPackage]     BIT            NULL,
    [RecordType]                     VARCHAR (100)  NULL
);

﻿CREATE TABLE [dbo].[XML_MFGRfq] (
    [Id]                       INT             IDENTITY (1, 1) NOT NULL,
    [RfqId]                    INT             NULL,
    [RfqName]                  NVARCHAR (100)  NULL,
    [RfqThumbnail]             VARCHAR (255)   NULL,
    [RfqDesc]                  NVARCHAR (MAX)  NULL,
    [Process]                  VARCHAR (150)   NULL,
    [Technique]                VARCHAR (150)   NULL,
    [Material]                 VARCHAR (150)   NULL,
    [PostProcess]              VARCHAR (150)   NULL,
    [IsLargePart]              BIT             NULL,
    [MaxQuantity]              NUMERIC (18, 3) NULL,
    [RfqDeepLinkUrl]           VARCHAR (255)   NULL,
    [BuyerState]               VARCHAR (50)    NULL,
    [BuyerCountry]             VARCHAR (50)    NULL,
    [BuyerIndustry]            VARCHAR (150)   NULL,
    [RecordDate]               DATETIME        NULL,
    [CreatedDate]              DATETIME2 (7)   NULL,
    [IsProcessed]              BIT             DEFAULT ((0)) NOT NULL,
    [IsIncludedInXml]          BIT             DEFAULT ((0)) NOT NULL,
    [IncludedDate]             DATETIME        NULL,
    [ProcessId]                INT             NULL,
    [IsIncludedInProcessXml]   BIT             NULL,
    [IncludedInProcessXmlDate] DATETIME        NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


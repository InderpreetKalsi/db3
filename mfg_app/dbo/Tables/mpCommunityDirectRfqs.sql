﻿CREATE TABLE [dbo].[mpCommunityDirectRfqs] (
    [Id]                          INT             IDENTITY (101, 1) NOT NULL,
    [LeadId]                      INT             NULL,
    [SupplierEmail]               VARCHAR (150)   NULL,
    [SupplierCompanyId]           INT             NULL,
    [BuyerIpAddress]              VARCHAR (150)   NULL,
    [BuyerEmail]                  VARCHAR (150)   NULL,
    [BuyerPhone]                  VARCHAR (50)    NULL,
    [PartDesc]                    NVARCHAR (MAX)  NULL,
    [PartFileId]                  INT             NULL,
    [Capability]                  VARCHAR (150)   NULL,
    [Material]                    VARCHAR (150)   NULL,
    [Quantity]                    INT             NULL,
    [LeadTime]                    DECIMAL (4, 1)  NULL,
    [LeadTimeDuration]            VARCHAR (50)    NULL,
    [NdaFileId]                   INT             NULL,
    [IsNdaRequired]               BIT             DEFAULT ((0)) NULL,
    [IsNdaAcceptedBySupplier]     BIT             DEFAULT ((0)) NULL,
    [NdaAcceptedDate]             DATETIME        NULL,
    [WantsMP]                     BIT             DEFAULT ((0)) NULL,
    [CreatedOn]                   DATETIME        DEFAULT (getutcdate()) NULL,
    [CommunitySupplierProfileURL] NVARCHAR (1500) NULL,
    [FirstName]                   NVARCHAR (256)  NULL,
    [LastName]                    NVARCHAR (256)  NULL,
    CONSTRAINT [pk_mpCommunityDirectRfqs_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [fk_mpCommunityDirectRfqs_mp_lead_LeadId_LeadId] FOREIGN KEY ([LeadId]) REFERENCES [dbo].[mp_lead] ([lead_id]),
    CONSTRAINT [fk_mpCommunityDirectRfqs_mp_special_files_NdaFileId_FILE_ID] FOREIGN KEY ([NdaFileId]) REFERENCES [dbo].[mp_special_files] ([FILE_ID]),
    CONSTRAINT [fk_mpCommunityDirectRfqs_mp_special_files_PartFileId_FILE_ID] FOREIGN KEY ([PartFileId]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


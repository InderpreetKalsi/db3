CREATE TABLE [dbo].[mpOrderManagementChangeLogs] (
    [Id]                INT           IDENTITY (1000, 1) NOT NULL,
    [Type]              VARCHAR (100) NULL,
    [OrderManagementId] INT           NULL,
    [RfqId]             INT           NULL,
    [PONumber]          VARCHAR (100) NULL,
    [PODate]            DATETIME      NULL,
    [IsMfgStandardPO]   BIT           NULL,
    [OldPOStatus]       VARCHAR (100) NULL,
    [NewPOStatus]       VARCHAR (100) NULL,
    [FileId]            INT           NULL,
    [SupplierContactId] INT           NULL,
    [CreatedOn]         DATETIME      CONSTRAINT [DF_mpOrderManagementChangeLogs_CreatedOn] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mpOrderManagementChangeLogs_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


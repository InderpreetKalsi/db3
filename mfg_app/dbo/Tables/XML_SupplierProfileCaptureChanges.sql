CREATE TABLE [dbo].[XML_SupplierProfileCaptureChanges] (
    [Id]        INT           IDENTITY (1, 1) NOT NULL,
    [CompanyId] INT           NOT NULL,
    [Event]     VARCHAR (250) NOT NULL,
    [CreatedOn] DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy] INT           NULL,
    CONSTRAINT [PK_XML_SupplierProfileCaptureChanges_CompanyId_CreatedOn] PRIMARY KEY CLUSTERED ([Id] ASC, [CompanyId] ASC, [CreatedOn] ASC) WITH (FILLFACTOR = 90)
);


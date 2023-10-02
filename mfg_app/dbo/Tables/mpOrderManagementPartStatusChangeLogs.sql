CREATE TABLE [dbo].[mpOrderManagementPartStatusChangeLogs] (
    [Id]                INT              IDENTITY (100, 1) NOT NULL,
    [RfqId]             INT              NULL,
    [RfqQuoteItemsId]   INT              NOT NULL,
    [OldStatus]         VARCHAR (100)    NOT NULL,
    [NewStatus]         VARCHAR (100)    NOT NULL,
    [CreatedOn]         DATETIME         CONSTRAINT [df_mpOrderManagementPartStatusChangeLogs_CreatedOn] DEFAULT (getutcdate()) NULL,
    [SupplierContactId] INT              NULL,
    [RfqPartId]         INT              NULL,
    [ReshapeUniqueId]   UNIQUEIDENTIFIER NULL,
    [IsDeleted]         BIT              DEFAULT ((0)) NULL,
    CONSTRAINT [pk_mpOrderManagementPartStatusChangeLogs_Id] PRIMARY KEY CLUSTERED ([Id] ASC, [RfqQuoteItemsId] ASC),
    CONSTRAINT [fk_mp_rfq_quote_items_OrderManagementId_mpOrderManagement_Id] FOREIGN KEY ([RfqQuoteItemsId]) REFERENCES [dbo].[mp_rfq_quote_items] ([rfq_quote_items_id])
);


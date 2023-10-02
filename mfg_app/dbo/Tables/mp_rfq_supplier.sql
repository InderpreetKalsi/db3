CREATE TABLE [dbo].[mp_rfq_supplier] (
    [rfq_supplier_id]   INT IDENTITY (1, 1) NOT NULL,
    [rfq_id]            INT NULL,
    [company_id]        INT NULL,
    [supplier_group_id] INT NULL,
    CONSTRAINT [PK_mp_rfq_supplier] PRIMARY KEY CLUSTERED ([rfq_supplier_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_supplier_mp_books] FOREIGN KEY ([supplier_group_id]) REFERENCES [dbo].[mp_books] ([book_id]) NOT FOR REPLICATION,
    CONSTRAINT [FK_mp_rfq_supplier_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_rfq_supplier_rfq_id]
    ON [dbo].[mp_rfq_supplier]([rfq_id] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table will hold information about the supplier/ Group of supplier assigned to respected RFQ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_supplier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is nothing but a Supplier ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_supplier', @level2type = N'COLUMN', @level2name = N'company_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'this is a supplier group ID, so that mean, when supplier_group_id selected then Contact_ID will be null and vice versa.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_supplier', @level2type = N'COLUMN', @level2name = N'supplier_group_id';


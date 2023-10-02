CREATE TABLE [dbo].[mp_rfq_supplier_read] (
    [rfq_supplier_read_id] INT  IDENTITY (1, 1) NOT NULL,
    [rfq_id]               INT  NOT NULL,
    [supplier_id]          INT  NOT NULL,
    [read_date]            DATE NULL,
    CONSTRAINT [PK_mp_rfq_supplier_read] PRIMARY KEY CLUSTERED ([rfq_supplier_read_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_supplier_read_supplier_id]
    ON [dbo].[mp_rfq_supplier_read]([supplier_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


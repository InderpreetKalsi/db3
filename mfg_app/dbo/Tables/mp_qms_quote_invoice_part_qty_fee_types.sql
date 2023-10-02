CREATE TABLE [dbo].[mp_qms_quote_invoice_part_qty_fee_types] (
    [qms_quote_invoice_part_qty_fee_type_id] INT             IDENTITY (1, 1) NOT NULL,
    [qms_quote_invoice_part_qty_id]          INT             NOT NULL,
    [fee_type_id]                            INT             NOT NULL,
    [value]                                  NUMERIC (18, 4) NULL,
    CONSTRAINT [PK_mp_qms_quote_invoice_part_qty_fee_types] PRIMARY KEY CLUSTERED ([qms_quote_invoice_part_qty_fee_type_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_invoice_part_qty_fee_types_mp_qms_quote_invoice_part_quantities] FOREIGN KEY ([qms_quote_invoice_part_qty_id]) REFERENCES [dbo].[mp_qms_quote_invoice_part_quantities] ([qms_quote_invoice_part_qty_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


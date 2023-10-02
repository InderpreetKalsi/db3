CREATE TABLE [dbo].[mp_qms_quote_invoice_part_quantities] (
    [qms_quote_invoice_part_qty_id] INT          IDENTITY (1, 1) NOT NULL,
    [qms_quote_invoice_part_id]     INT          NOT NULL,
    [part_qty]                      NUMERIC (18) NULL,
    [part_qty_unit_id]              INT          NULL,
    [qty_level]                     SMALLINT     NULL,
    [is_chk_other_qty]              BIT          DEFAULT ((0)) NOT NULL,
    [is_deleted]                    BIT          DEFAULT ((0)) NOT NULL,
    [modified_date]                 DATETIME     NULL,
    CONSTRAINT [PK_mp_qms_quote_invoice_part_quantities] PRIMARY KEY CLUSTERED ([qms_quote_invoice_part_qty_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_invoice_part_quantities_mp_qms_quote_invoice_parts] FOREIGN KEY ([qms_quote_invoice_part_id]) REFERENCES [dbo].[mp_qms_quote_invoice_parts] ([qms_quote_invoice_part_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


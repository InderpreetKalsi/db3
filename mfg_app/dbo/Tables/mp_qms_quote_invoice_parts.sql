CREATE TABLE [dbo].[mp_qms_quote_invoice_parts] (
    [qms_quote_invoice_part_id] INT      IDENTITY (1, 1) NOT NULL,
    [qms_quote_invoice_id]      INT      NOT NULL,
    [qms_quote_part_id]         INT      NOT NULL,
    [created_date]              DATETIME DEFAULT (getutcdate()) NOT NULL,
    [IsPartOfInvoice]           BIT      NULL,
    CONSTRAINT [PK_mp_qms_quote_invoice_parts] PRIMARY KEY CLUSTERED ([qms_quote_invoice_part_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_invoice_parts_mp_qms_quote_invoices] FOREIGN KEY ([qms_quote_invoice_id]) REFERENCES [dbo].[mp_qms_quote_invoices] ([qms_quote_invoice_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


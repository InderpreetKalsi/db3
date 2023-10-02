CREATE TABLE [dbo].[mp_invoice_payments] (
    [inv_payment_id]         INT            IDENTITY (1, 1) NOT NULL,
    [zoho_invoiceseqid]      INT            NOT NULL,
    [seqid]                  INT            NOT NULL,
    [invoiceId]              BIGINT         NULL,
    [payment_id]             NVARCHAR (100) NULL,
    [payment_mode]           NVARCHAR (100) NULL,
    [invoice_payment_id]     NVARCHAR (100) NULL,
    [gateway_transaction_id] NVARCHAR (500) NULL,
    [description]            NVARCHAR (MAX) NULL,
    [date]                   DATETIME       NULL,
    [reference_number]       NVARCHAR (500) NULL,
    [amount]                 MONEY          NULL,
    CONSTRAINT [PK_zoho_Invoice_Payments] PRIMARY KEY CLUSTERED ([inv_payment_id] ASC) WITH (FILLFACTOR = 90)
);


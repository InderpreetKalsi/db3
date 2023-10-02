CREATE TABLE [dbo].[mp_mst_qms_quote_invoice_seq_no] (
    [qms_invoice_seq_id]      INT IDENTITY (1, 1) NOT NULL,
    [company_id]              INT NOT NULL,
    [invoice_starting_seq_no] INT NULL,
    PRIMARY KEY CLUSTERED ([qms_invoice_seq_id] ASC, [company_id] ASC) WITH (FILLFACTOR = 90)
);


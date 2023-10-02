CREATE TABLE [dbo].[mp_rfq_quote_files] (
    [rfq_quote_file_id]          INT      IDENTITY (1, 1) NOT NULL,
    [rfq_quote_SupplierQuote_id] INT      NULL,
    [file_id]                    INT      NULL,
    [creation_date]              DATETIME NULL,
    [status_id]                  INT      NULL,
    [message_id]                 INT      NULL,
    CONSTRAINT [PK_mp_rfq_quote_files] PRIMARY KEY CLUSTERED ([rfq_quote_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_quote_files_mp_rfq_quote_SupplierQuote] FOREIGN KEY ([rfq_quote_SupplierQuote_id]) REFERENCES [dbo].[mp_rfq_quote_SupplierQuote] ([rfq_quote_SupplierQuote_id])
);


GO
ALTER TABLE [dbo].[mp_rfq_quote_files] NOCHECK CONSTRAINT [FK_mp_rfq_quote_files_mp_rfq_quote_SupplierQuote];


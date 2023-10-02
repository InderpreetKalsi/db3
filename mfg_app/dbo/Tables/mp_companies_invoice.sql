CREATE TABLE [dbo].[mp_companies_invoice] (
    [company_invoice_id] INT            IDENTITY (1, 1) NOT NULL,
    [zoho_seqid]         INT            NOT NULL,
    [invoice_id]         BIGINT         NULL,
    [number]             NVARCHAR (500) NULL,
    [status]             NVARCHAR (500) NULL,
    [invoice_date]       DATETIME       NULL,
    [customer_id]        BIGINT         NULL,
    [total]              MONEY          NULL,
    [payment_made]       MONEY          NULL,
    [balance]            MONEY          NULL,
    [credits_applied]    MONEY          NULL,
    [write_off_amount]   MONEY          NULL,
    [created_on]         DATETIME       NULL,
    [modified_on]        DATETIME       NULL,
    [due_date]           DATETIME       NULL,
    CONSTRAINT [PK_mp_companies_invoice] PRIMARY KEY CLUSTERED ([company_invoice_id] ASC) WITH (FILLFACTOR = 90)
);


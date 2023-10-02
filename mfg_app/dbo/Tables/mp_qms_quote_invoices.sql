CREATE TABLE [dbo].[mp_qms_quote_invoices] (
    [qms_quote_invoice_id]  INT             IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]          INT             NOT NULL,
    [qms_customer_id]       INT             NOT NULL,
    [invoice_id]            INT             NULL,
    [invoice_no]            VARCHAR (150)   NULL,
    [invoice_name]          NVARCHAR (250)  NULL,
    [purchase_order_number] INT             NULL,
    [reference_no]          NVARCHAR (150)  NULL,
    [currency_id]           INT             NULL,
    [invoice_date]          DATETIME        NULL,
    [payment_term_id]       INT             NULL,
    [status_id]             INT             DEFAULT ((20)) NOT NULL,
    [notes]                 NVARCHAR (2000) NULL,
    [is_deleted]            BIT             DEFAULT ((0)) NULL,
    [created_by]            INT             NOT NULL,
    [created_date]          DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [modified_date]         DATETIME        NULL,
    CONSTRAINT [PK_mp_qms_quote_invoices] PRIMARY KEY CLUSTERED ([qms_quote_invoice_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [fk_mp_qms_quote_invoices_mp_mst_currency] FOREIGN KEY ([currency_id]) REFERENCES [dbo].[mp_mst_currency] ([currency_id]),
    CONSTRAINT [fk_mp_qms_quote_invoices_mp_mst_qms_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[mp_mst_qms_status] ([qms_status_id])
);


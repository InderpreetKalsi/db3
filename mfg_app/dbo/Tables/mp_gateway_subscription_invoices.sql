CREATE TABLE [dbo].[mp_gateway_subscription_invoices] (
    [id]                      INT             IDENTITY (1001, 1) NOT NULL,
    [subscription_invoice_id] VARCHAR (250)   NOT NULL,
    [subscription_id]         VARCHAR (250)   NOT NULL,
    [invoice_no]              VARCHAR (250)   NULL,
    [invoice_payment_id]      VARCHAR (250)   NULL,
    [invoice_date]            DATETIME        NULL,
    [amount_due]              NUMERIC (18, 2) NULL,
    [amount_paid]             NUMERIC (18, 2) NULL,
    [amount_remaining]        NUMERIC (18, 2) NULL,
    [discount]                NUMERIC (18, 2) NULL,
    [due_date]                DATETIME        NULL,
    [status]                  VARCHAR (250)   NULL,
    [billing_method]          VARCHAR (250)   NULL,
    [invoice_pdf]             VARCHAR (1000)  NULL,
    [invoice_hosted_url]      VARCHAR (1000)  NULL,
    [created]                 DATETIME        DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_gateway_subscription_invoices_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


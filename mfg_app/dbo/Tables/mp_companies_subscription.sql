CREATE TABLE [dbo].[mp_companies_subscription] (
    [company_subscription_id]   INT      IDENTITY (1, 1) NOT NULL,
    [sales_representative_id]   INT      NULL,
    [company_id]                INT      NOT NULL,
    [contact_id]                INT      NULL,
    [account_type_id]           INT      NULL,
    [payment_method_id]         INT      NULL,
    [payment_frequency_id]      INT      NULL,
    [invoice_no]                INT      NULL,
    [invoice_date]              DATETIME NULL,
    [price]                     MONEY    NULL,
    [actual_invoice_amount]     MONEY    NULL,
    [discounted_invoice_amount] MONEY    NULL,
    [subscription_start_date]   DATETIME NULL,
    [subscription_end_date]     DATETIME NULL,
    [is_autorenewal]            BIT      NULL,
    [isactive]                  BIT      NULL,
    [created]                   DATETIME NULL,
    [created_by]                INT      NULL,
    [modified]                  DATETIME NULL,
    [modified_by]               INT      NULL,
    CONSTRAINT [pk_mp_companies_subscription] PRIMARY KEY CLUSTERED ([company_subscription_id] ASC, [company_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_company_subscriptions] (
    [company_subscription_id]      INT           IDENTITY (1, 1) NOT NULL,
    [zoho_company_subscription_id] INT           NOT NULL,
    [payment_duration]             VARCHAR (50)  NULL,
    [subscription_start_date]      DATETIME      NULL,
    [subscription_end_date]        DATETIME      NULL,
    [zoho_subscription_id]         VARCHAR (500) NULL,
    [cc_gateway]                   VARCHAR (100) NULL,
    [is_autorenewal]               BIT           NULL,
    [created_on]                   DATETIME      NULL,
    [modified_on]                  DATETIME      NULL,
    [zoho_id]                      BIGINT        NULL,
    [customer_id]                  BIGINT        NULL,
    [account_zoho_id]              BIGINT        NULL,
    [currency_symbol]              NVARCHAR (10) NULL,
    [membership_total_amount]      MONEY         NULL,
    [invoice_total_amount]         MONEY         NULL,
    CONSTRAINT [PK_mp_company_subscriptions] PRIMARY KEY CLUSTERED ([company_subscription_id] ASC) WITH (FILLFACTOR = 90)
);


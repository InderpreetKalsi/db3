CREATE TABLE [dbo].[mp_stripe_customer_subscription_invoices] (
    [id]                 INT             IDENTITY (1001, 1) NOT NULL,
    [stripe_invoice_id]  VARCHAR (250)   NOT NULL,
    [subscription_id]    INT             NOT NULL,
    [invoice_no]         VARCHAR (250)   NULL,
    [amount_due]         NUMERIC (18, 2) NULL,
    [amount_paid]        NUMERIC (18, 2) NULL,
    [amount_remaining]   NUMERIC (18, 2) NULL,
    [discount]           NUMERIC (18, 2) NULL,
    [due_date]           DATETIME        NULL,
    [status]             VARCHAR (250)   NULL,
    [billing_method]     VARCHAR (250)   NULL,
    [invoice_pdf]        VARCHAR (1000)  NULL,
    [invoice_hosted_url] VARCHAR (1000)  NULL,
    [created]            DATETIME        CONSTRAINT [DF_mp_stripe_customer_subscription_invoices_created] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_stripe_customer_subscription_invoices] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_stripe_customer_subscription_invoices_mp_stripe_customer_subscriptions] FOREIGN KEY ([subscription_id]) REFERENCES [dbo].[mp_stripe_customer_subscriptions] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_stripe_customer_subscription_invoices]
    ON [dbo].[mp_stripe_customer_subscription_invoices]([subscription_id] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[tr_update_created]  ON  [dbo].[mp_stripe_customer_subscription_invoices]
AFTER INSERT
AS 
BEGIN
	
	
	UPDATE [mp_stripe_customer_subscription_invoices] 
		SET  created = GETUTCDATE() 
	WHERE created IS NULL; 
	
END

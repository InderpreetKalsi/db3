CREATE TABLE [dbo].[mp_stripe_customers] (
    [id]                 INT           IDENTITY (1001, 1) NOT NULL,
    [supplier_id]        INT           NULL,
    [stripe_customer_id] VARCHAR (250) NULL,
    [created]            DATETIME      CONSTRAINT [DF_mp_stripe_customers_created] DEFAULT (getutcdate()) NULL,
    [is_active]          BIT           CONSTRAINT [DF_mp_stripe_customers_is_active] DEFAULT ((1)) NULL,
    [deleted_on]         DATETIME      NULL,
    [company_id]         INT           NULL,
    CONSTRAINT [pk_mp_stripe_customers_stripe_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_mp_stripe_customers]
    ON [dbo].[mp_stripe_customers]([supplier_id] ASC, [stripe_customer_id] ASC) WITH (FILLFACTOR = 90);


GO

CREATE  TRIGGER [dbo].[tr_update_company_id]  ON  [dbo].[mp_stripe_customers]
AFTER INSERT
AS 
BEGIN
	
	UPDATE a
	SET a.company_id = b.company_id
	FROM mp_stripe_customers	a (NOLOCK)
	JOIN mp_contacts			b (NOLOCK) ON a.supplier_id = b.contact_id
	WHERE a.company_id IS NULL
	

END

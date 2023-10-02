CREATE TABLE [dbo].[mp_stripe_pricing_plans] (
    [id]                     INT             IDENTITY (1001, 1) NOT NULL,
    [stripe_pricing_plan_id] VARCHAR (250)   NULL,
    [product_id]             INT             NULL,
    [price]                  NUMERIC (12, 2) NULL,
    [billing_interval]       VARCHAR (100)   NULL,
    [is_active]              BIT             DEFAULT ((1)) NULL,
    [created]                DATETIME        NULL,
    CONSTRAINT [pk_mp_stripe_plans_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_stripe_plans_mp_stripe_products] FOREIGN KEY ([product_id]) REFERENCES [dbo].[mp_stripe_products] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [ix_mp_stripe_plans]
    ON [dbo].[mp_stripe_pricing_plans]([stripe_pricing_plan_id] ASC, [product_id] ASC) WITH (FILLFACTOR = 90);


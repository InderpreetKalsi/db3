CREATE TABLE [dbo].[mp_gateway_subscription_pricing_plans] (
    [id]                           INT             IDENTITY (1001, 1) NOT NULL,
    [subscription_pricing_plan_id] VARCHAR (250)   NULL,
    [plan_code]                    VARCHAR (250)   NULL,
    [product_id]                   INT             NULL,
    [price]                        NUMERIC (12, 2) NULL,
    [billing_interval]             VARCHAR (100)   NULL,
    [is_active]                    BIT             DEFAULT ((1)) NULL,
    [created]                      DATETIME        NULL,
    CONSTRAINT [pk_mp_gateway_subscription_pricing_plans_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_gateway_subscription_pricing_plans_mp_gateway_subscription_products] FOREIGN KEY ([product_id]) REFERENCES [dbo].[mp_gateway_subscription_products] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


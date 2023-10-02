CREATE TABLE [dbo].[mp_stripe_customer_subscriptions] (
    [id]                     INT           IDENTITY (1001, 1) NOT NULL,
    [stripe_subscription_id] VARCHAR (250) NOT NULL,
    [customer_id]            INT           NOT NULL,
    [plan_id]                INT           NOT NULL,
    [subscription_start]     DATETIME      NULL,
    [subscription_end]       DATETIME      NULL,
    [status]                 VARCHAR (250) NULL,
    [created]                DATETIME      CONSTRAINT [DF_mp_stripe_customer_subscriptions_created] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_stripe_customer_subscriptions] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_stripe_customer_subscriptions_mp_stripe_customers] FOREIGN KEY ([customer_id]) REFERENCES [dbo].[mp_stripe_customers] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_mp_stripe_customer_subscriptions_mp_stripe_pricing_plans] FOREIGN KEY ([plan_id]) REFERENCES [dbo].[mp_stripe_pricing_plans] ([id])
);


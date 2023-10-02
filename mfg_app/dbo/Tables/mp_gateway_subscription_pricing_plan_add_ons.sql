CREATE TABLE [dbo].[mp_gateway_subscription_pricing_plan_add_ons] (
    [id]              INT             IDENTITY (1001, 1) NOT NULL,
    [pricing_plan_id] INT             NOT NULL,
    [addon_code]      VARCHAR (250)   NULL,
    [addon_price]     NUMERIC (18, 4) NULL,
    [is_active]       BIT             CONSTRAINT [DF__mp_gatewa__is_ac__23AFF913] DEFAULT ((1)) NULL,
    [created]         DATETIME        NULL,
    CONSTRAINT [pk_mp_gateway_subscription_pricing_plan_add_ons_id] PRIMARY KEY CLUSTERED ([id] ASC, [pricing_plan_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_gateway_subscription_pricing_plan_add_ons_mp_gateway_subscription_pricing_plans] FOREIGN KEY ([pricing_plan_id]) REFERENCES [dbo].[mp_gateway_subscription_pricing_plans] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


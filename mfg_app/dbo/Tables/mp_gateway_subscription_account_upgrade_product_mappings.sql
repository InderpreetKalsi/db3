CREATE TABLE [dbo].[mp_gateway_subscription_account_upgrade_product_mappings] (
    [id]         INT IDENTITY (1001, 1) NOT NULL,
    [upgrade_id] INT NULL,
    [product_id] INT NULL,
    CONSTRAINT [pk_mp_gateway_subscription_account_upgrade_product_mappings_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_gateway_subscription_account_upgrade_product_mappings_mp_gateway_subscription_account_upgrades] FOREIGN KEY ([upgrade_id]) REFERENCES [dbo].[mp_gateway_subscription_account_upgrades] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_mp_gateway_subscription_account_upgrade_product_mappings_mp_gateway_subscription_products] FOREIGN KEY ([product_id]) REFERENCES [dbo].[mp_gateway_subscription_products] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


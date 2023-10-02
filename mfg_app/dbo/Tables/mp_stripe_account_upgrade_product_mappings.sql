CREATE TABLE [dbo].[mp_stripe_account_upgrade_product_mappings] (
    [id]         INT IDENTITY (1001, 1) NOT NULL,
    [upgrade_id] INT NULL,
    [product_id] INT NULL,
    CONSTRAINT [pk_mp_stripe_upgrade_products_mappings_stripe_upgrade_products_mappings_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_stripe_upgrade_products_mappings_mp_stripe_products] FOREIGN KEY ([product_id]) REFERENCES [dbo].[mp_stripe_products] ([id]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_mp_stripe_upgrade_products_mappings_mp_stripe_upgrades] FOREIGN KEY ([upgrade_id]) REFERENCES [dbo].[mp_stripe_account_upgrades] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


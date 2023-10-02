CREATE TABLE [dbo].[mp_stripe_product_features] (
    [id]         INT           IDENTITY (1001, 1) NOT NULL,
    [product_id] INT           NOT NULL,
    [feature]    VARCHAR (250) NULL,
    [parent_id]  INT           NULL,
    [value]      VARCHAR (250) NULL,
    [is_include] BIT           CONSTRAINT [DF_mp_stripe_pricing_plan_features_is_active] DEFAULT ((1)) NULL,
    [is_active]  BIT           CONSTRAINT [DF_mp_stripe_product_features_is_active] DEFAULT ((1)) NULL,
    [created]    DATETIME      CONSTRAINT [DF_mp_stripe_pricing_plan_features_created] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_stripe_pricing_plan_features] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_stripe_pricing_plan_features_mp_stripe_products] FOREIGN KEY ([product_id]) REFERENCES [dbo].[mp_stripe_products] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_stripe_pricing_plan_features]
    ON [dbo].[mp_stripe_product_features]([product_id] ASC) WITH (FILLFACTOR = 90);


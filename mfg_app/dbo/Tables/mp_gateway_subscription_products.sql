CREATE TABLE [dbo].[mp_gateway_subscription_products] (
    [id]                      INT           IDENTITY (1001, 1) NOT NULL,
    [subscription_product_id] VARCHAR (250) NULL,
    [actual_name]             VARCHAR (250) NULL,
    [name]                    VARCHAR (250) NULL,
    [is_enable]               BIT           CONSTRAINT [DF_mp_gateway_subscription_products_is_enable] DEFAULT ((1)) NULL,
    [is_active]               BIT           CONSTRAINT [DF_mp_gateway_subscription_products_is_active] DEFAULT ((1)) NULL,
    [created]                 DATETIME      NULL,
    [ProductPriceAPIId]       VARCHAR (250) NULL,
    CONSTRAINT [pk_mp_gateway_subscription_products_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


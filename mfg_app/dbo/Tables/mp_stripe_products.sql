CREATE TABLE [dbo].[mp_stripe_products] (
    [id]                INT           IDENTITY (1001, 1) NOT NULL,
    [stripe_product_id] VARCHAR (250) NULL,
    [actual_name]       VARCHAR (250) NULL,
    [name]              VARCHAR (250) NULL,
    [is_enable]         BIT           CONSTRAINT [DF_mp_stripe_products_is_enable] DEFAULT ((1)) NULL,
    [is_active]         BIT           CONSTRAINT [DF__mp_stripe__is_ac__6808EA49] DEFAULT ((1)) NULL,
    [created]           DATETIME      NULL,
    CONSTRAINT [pk_mp_stripe_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_gateway_subscription_product_process_mappings] (
    [Id]             INT IDENTITY (1000, 1) NOT NULL,
    [ProductId]      INT NULL,
    [PartCategoryId] INT NULL,
    CONSTRAINT [pk_mp_gateway_subscription_product_process_mappings_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


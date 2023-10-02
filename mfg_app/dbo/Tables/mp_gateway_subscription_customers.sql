CREATE TABLE [dbo].[mp_gateway_subscription_customers] (
    [id]                       INT           IDENTITY (1001, 1) NOT NULL,
    [gateway_id]               INT           NULL,
    [company_id]               INT           NULL,
    [supplier_id]              INT           NULL,
    [subscription_customer_id] VARCHAR (250) NULL,
    [created]                  DATETIME      CONSTRAINT [DF_mp_gateway_subscription_customers_created] DEFAULT (getutcdate()) NULL,
    [is_active]                BIT           CONSTRAINT [DF_mp_gateway_subscription_customers_is_active] DEFAULT ((1)) NULL,
    [deleted_on]               DATETIME      NULL,
    [delete_by]                INT           NULL,
    CONSTRAINT [pk_mp_gateway_subscription_customers_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_gateway_subscription_customers_mp_contacts] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_mp_gateway_subscription_customers_mp_system_parameters] FOREIGN KEY ([gateway_id]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


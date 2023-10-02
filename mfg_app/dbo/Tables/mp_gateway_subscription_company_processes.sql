CREATE TABLE [dbo].[mp_gateway_subscription_company_processes] (
    [id]               INT IDENTITY (1, 1) NOT NULL,
    [company_id]       INT NULL,
    [part_category_id] INT NULL,
    [is_active]        BIT DEFAULT ((1)) NULL,
    CONSTRAINT [pk_mp_stripe_company_processes] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_mp_gateway_subscription_company_processes_company_id_part_category_id]
    ON [dbo].[mp_gateway_subscription_company_processes]([company_id] ASC, [part_category_id] ASC) WITH (FILLFACTOR = 90);


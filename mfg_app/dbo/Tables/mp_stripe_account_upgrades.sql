CREATE TABLE [dbo].[mp_stripe_account_upgrades] (
    [id]            INT           IDENTITY (1001, 1) NOT NULL,
    [upgrade_title] VARCHAR (250) NULL,
    [is_active]     BIT           DEFAULT ((1)) NULL,
    CONSTRAINT [pk_mp_stripe_upgrades_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


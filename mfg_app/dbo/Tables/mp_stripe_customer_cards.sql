CREATE TABLE [dbo].[mp_stripe_customer_cards] (
    [id]              INT           IDENTITY (1001, 1) NOT NULL,
    [customer_id]     INT           NULL,
    [stripe_card_id]  VARCHAR (250) NULL,
    [card_type]       VARCHAR (150) NULL,
    [card_brand]      VARCHAR (150) NULL,
    [country]         VARCHAR (150) NULL,
    [card_last4digit] VARCHAR (500) NULL,
    [exp_month]       VARCHAR (500) NULL,
    [exp_year]        VARCHAR (500) NULL,
    [is_active]       BIT           DEFAULT ((1)) NULL,
    [created]         DATETIME      CONSTRAINT [DF_mp_stripe_customer_cards_created] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [pk_mp_stripe_customer_cards_customer_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_stripe_customer_cards_mp_stripe_customers] FOREIGN KEY ([customer_id]) REFERENCES [dbo].[mp_stripe_customers] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [ix_mp_stripe_customer_cardss]
    ON [dbo].[mp_stripe_customer_cards]([customer_id] ASC) WITH (FILLFACTOR = 90);


CREATE TABLE [dbo].[mp_buyer_dashboard_new_suppliers] (
    [Id]              INT      IDENTITY (100, 1) NOT NULL,
    [BuyerId]         INT      NOT NULL,
    [SupplierId]      INT      NULL,
    [CreatedOn]       DATETIME DEFAULT (getutcdate()) NULL,
    [ValidUntil]      DATETIME NULL,
    [IsMessageSent]   BIT      DEFAULT ((0)) NULL,
    [IsProfileViewed] BIT      DEFAULT ((0)) NULL,
    CONSTRAINT [pk_mp_buyer_dashboard_new_suppliers_Id_BuyerId] PRIMARY KEY CLUSTERED ([BuyerId] ASC, [Id] ASC) WITH (FILLFACTOR = 90)
);


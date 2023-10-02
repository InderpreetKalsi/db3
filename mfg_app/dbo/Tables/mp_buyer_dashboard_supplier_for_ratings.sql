CREATE TABLE [dbo].[mp_buyer_dashboard_supplier_for_ratings] (
    [Id]             INT            IDENTITY (100, 1) NOT NULL,
    [RfqId]          INT            NOT NULL,
    [RfqClosedDate]  DATE           NULL,
    [RfqAwardDate]   DATE           NULL,
    [BuyerId]        INT            NOT NULL,
    [SupplierId]     INT            NULL,
    [QuoteDate]      DATE           NULL,
    [AwardedDate]    DATE           NULL,
    [RatingMessage]  VARCHAR (1100) NULL,
    [IsAlreadyRated] BIT            CONSTRAINT [DF__mp_buyer___IsAlr__61AD2B8C] DEFAULT ((0)) NULL,
    [RatedRfq]       BIT            NULL,
    [IsExclude]      BIT            CONSTRAINT [DF_mp_buyer_dashboard_supplier_for_ratings_IsExclude] DEFAULT ((0)) NULL,
    [LastRatedOn]    DATE           NULL,
    [CreatedOn]      DATETIME       CONSTRAINT [DF__mp_buyer___Creat__62A14FC5] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_buyer_dashboard_supplier_for_ratings] PRIMARY KEY CLUSTERED ([Id] ASC, [RfqId] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_buyer_dashboard_supplier_for_ratings]
    ON [dbo].[mp_buyer_dashboard_supplier_for_ratings]([BuyerId] ASC, [Id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_buyer_dashboard_supplier_for_ratings_BuyerId_IsAlreadyRated]
    ON [dbo].[mp_buyer_dashboard_supplier_for_ratings]([BuyerId] ASC, [IsAlreadyRated] ASC)
    INCLUDE([SupplierId]) WITH (FILLFACTOR = 90);


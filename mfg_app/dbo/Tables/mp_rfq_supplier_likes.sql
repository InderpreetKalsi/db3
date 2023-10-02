CREATE TABLE [dbo].[mp_rfq_supplier_likes] (
    [rfq_supplier_likes_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                INT      NOT NULL,
    [company_id]            INT      NULL,
    [contact_id]            INT      NOT NULL,
    [is_rfq_like]           BIT      NOT NULL,
    [like_date]             DATETIME NOT NULL,
    CONSTRAINT [PK_mp_rfq_supplier_likes] PRIMARY KEY CLUSTERED ([rfq_supplier_likes_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_supplier_likes_contact_id]
    ON [dbo].[mp_rfq_supplier_likes]([contact_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'0 - Dislike RFQ, 1- Liked RFQ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_supplier_likes', @level2type = N'COLUMN', @level2name = N'is_rfq_like';


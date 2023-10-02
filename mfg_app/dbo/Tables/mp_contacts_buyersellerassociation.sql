CREATE TABLE [dbo].[mp_contacts_buyersellerassociation] (
    [cont_buyersellerassociation_id] INT      IDENTITY (1, 1) NOT NULL,
    [seller_cont_id]                 INT      NOT NULL,
    [buyer_cont_id]                  INT      NOT NULL,
    [status_id]                      SMALLINT NOT NULL,
    [created_on]                     DATETIME DEFAULT (getdate()) NOT NULL,
    [default_buyer_dashboard]        BIT      NOT NULL,
    CONSTRAINT [PK_mp_cont_buyersellerassoc] PRIMARY KEY CLUSTERED ([cont_buyersellerassociation_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_contacts_buyersellerassociation_mp_contacts] FOREIGN KEY ([buyer_cont_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_contacts_buyersellerassociation_mp_contacts1] FOREIGN KEY ([seller_cont_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_contacts_buyersellerassociation_mp_mst_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[mp_mst_status] ([status_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Manager relation beetween Supplier contact and Buyer contact.  Used in Marketplace to link a buyer contact to a supplier contact.  This table also controls what dashboard is shown by default.  (considering same contact can act as buyer and seller this table is design)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_buyersellerassociation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Seller Company  Idenifier linked to mp_contacts table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_buyersellerassociation', @level2type = N'COLUMN', @level2name = N'seller_cont_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Buyer company Identifier, linked to mp_contacts table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_buyersellerassociation', @level2type = N'COLUMN', @level2name = N'buyer_cont_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This allows the buyers and suppliers to set which dashboard they want to see when they log in if they have both a buyer and supplier account.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_buyersellerassociation', @level2type = N'COLUMN', @level2name = N'default_buyer_dashboard';


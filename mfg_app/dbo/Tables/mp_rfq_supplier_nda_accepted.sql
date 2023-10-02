CREATE TABLE [dbo].[mp_rfq_supplier_nda_accepted] (
    [rfq_supplier_nda_accepted]       INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                          INT      NOT NULL,
    [contact_id]                      INT      NOT NULL,
    [is_prefered_nda_type_accepted]   BIT      NOT NULL,
    [prefered_nda_type_accepted_date] DATETIME NOT NULL,
    [is_nda_verbiage_accepted]        BIT      NULL,
    [nda_verbiage_accepted_date]      DATETIME NULL,
    [isapprove_by_buyer]              BIT      NULL,
    [buyer_approve_date]              DATETIME NULL,
    CONSTRAINT [PK_mp_rfq_supplier_nda_accepted] PRIMARY KEY CLUSTERED ([rfq_supplier_nda_accepted] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_supplier_nda_accepted_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


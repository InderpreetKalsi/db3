CREATE TABLE [dbo].[mp_rfq_quote_SupplierQuote] (
    [rfq_quote_SupplierQuote_id]   INT            IDENTITY (1, 1) NOT NULL,
    [rfq_id]                       INT            NOT NULL,
    [contact_id]                   INT            NOT NULL,
    [payment_terms]                NVARCHAR (500) NULL,
    [is_payterm_accepted]          BIT            NULL,
    [is_supplier_pay_for_Shipping] BIT            NULL,
    [is_parts_made_in_us]          BIT            NULL,
    [quote_reference_number]       VARCHAR (100)  NULL,
    [is_quote_submitted]           BIT            CONSTRAINT [DF_mp_rfq_quote_SupplierQuote_is_quote_submitted] DEFAULT ((0)) NOT NULL,
    [is_reviewed]                  BIT            CONSTRAINT [DF_mp_rfq_quote_SupplierQuote_is_reviewed] DEFAULT ((0)) NOT NULL,
    [quote_date]                   DATETIME       NOT NULL,
    [quote_expiry_date]            DATETIME       NULL,
    [is_rfq_resubmitted]           BIT            DEFAULT ((0)) NULL,
    [rfq_resubmitted_date]         DATETIME       NULL,
    [is_quote_declined]            BIT            NULL,
    [buyer_feedback_id]            INT            NULL,
    [IsViewed]                     BIT            DEFAULT ((0)) NULL,
    [IsAllowRequoting]             BIT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_mp_rfq_quote_SupplierQuote] PRIMARY KEY CLUSTERED ([rfq_quote_SupplierQuote_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_quote_SupplierQuote_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_rfq_quote_SupplierQuote_rfq_id]
    ON [dbo].[mp_rfq_quote_SupplierQuote]([rfq_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_quote_SupplierQuote_contact_id_is_rfq_resubmitted]
    ON [dbo].[mp_rfq_quote_SupplierQuote]([contact_id] ASC, [is_rfq_resubmitted] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [mp_rfq_quote_SupplierQuote_contact_id]
    ON [dbo].[mp_rfq_quote_SupplierQuote]([contact_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_rfq_quote_SupplierQuote_is_quote_submitted_is_rfq_resubmitted]
    ON [dbo].[mp_rfq_quote_SupplierQuote]([is_quote_submitted] ASC, [is_rfq_resubmitted] ASC)
    INCLUDE([rfq_id], [contact_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Supplier contact id', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_quote_SupplierQuote', @level2type = N'COLUMN', @level2name = N'contact_id';


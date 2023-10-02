CREATE TABLE [dbo].[tmp_ssis_legacy_qouted_rfq] (
    [RFQID]                                   NVARCHAR (1000) NOT NULL,
    [Supplier_Contact_id]                     NVARCHAR (1000) NOT NULL,
    [Supplier_company_id]                     NVARCHAR (1000) NOT NULL,
    [is_prefered_nda_type_accepted]           NVARCHAR (1000) NOT NULL,
    [prefered_nda_type_accepted_date]         NVARCHAR (1000) NOT NULL,
    [payment_terms]                           NVARCHAR (1000) NOT NULL,
    [is_payterm_accepted]                     NVARCHAR (1000) NOT NULL,
    [QuoteReferenceNumber]                    NVARCHAR (1000) NOT NULL,
    [IsSubmittedQuote]                        NVARCHAR (1000) NOT NULL,
    [QuoteCreationDate]                       NVARCHAR (1000) NOT NULL,
    [QuoteExpirationDate]                     NVARCHAR (1000) NOT NULL,
    [PMS_ITEM_ID]                             NVARCHAR (1000) NOT NULL,
    [grid_article]                            NVARCHAR (1000) NOT NULL,
    [per_unit_price]                          NVARCHAR (1000) NOT NULL,
    [tooling_amount]                          NVARCHAR (1000) NOT NULL,
    [miscellaneous_amount]                    NVARCHAR (1000) NOT NULL,
    [shipping_amount]                         NVARCHAR (1000) NOT NULL,
    [is_awarded]                              NVARCHAR (1000) NOT NULL,
    [QUANTITY_REF]                            NVARCHAR (1000) NOT NULL,
    [is_award_accepted]                       NVARCHAR (1000) NOT NULL,
    [AwardAcceptanceStatusDate]               NVARCHAR (1000) NOT NULL,
    [is_created_mp_rfq_quote_supplierquote]   BIT             DEFAULT ((0)) NULL,
    [is_created_mp_rfq_quote_items]           BIT             DEFAULT ((0)) NULL,
    [is_created_mp_rfq_supplier_nda_accepted] BIT             DEFAULT ((0)) NULL,
    [is_created_mp_rfq_quote_suplierStatuses] BIT             DEFAULT ((0)) NULL
);


GO
CREATE NONCLUSTERED INDEX [nc_index_tmp_ssis_legacy_qouted_rfq_rfq_id]
    ON [dbo].[tmp_ssis_legacy_qouted_rfq]([RFQID] ASC) WITH (FILLFACTOR = 90);


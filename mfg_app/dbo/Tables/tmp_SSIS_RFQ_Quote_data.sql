﻿CREATE TABLE [dbo].[tmp_SSIS_RFQ_Quote_data] (
    [RFQID]                           NVARCHAR (1000) NULL,
    [Supplier_Contact_id]             NVARCHAR (1000) NULL,
    [Supplier_company_id]             NVARCHAR (1000) NULL,
    [is_prefered_nda_type_accepted]   NVARCHAR (1000) NULL,
    [prefered_nda_type_accepted_date] NVARCHAR (1000) NULL,
    [payment_terms]                   NVARCHAR (1000) NULL,
    [is_payterm_accepted]             NVARCHAR (1000) NULL,
    [QuoteReferenceNumber]            NVARCHAR (1000) NULL,
    [IsSubmittedQuote]                NVARCHAR (1000) NULL,
    [QuoteCreationDate]               NVARCHAR (1000) NULL,
    [QuoteExpirationDate]             NVARCHAR (1000) NULL,
    [PMS_ITEM_ID]                     NVARCHAR (1000) NULL,
    [grid_article]                    NVARCHAR (1000) NULL,
    [per_unit_price]                  NVARCHAR (1000) NULL,
    [tooling_amount]                  NVARCHAR (1000) NULL,
    [miscellaneous_amount]            NVARCHAR (1000) NULL,
    [shipping_amount]                 NVARCHAR (1000) NULL,
    [is_awarded]                      NVARCHAR (1000) NULL,
    [QUANTITY_REF]                    NVARCHAR (1000) NULL,
    [is_award_accepted]               NVARCHAR (1000) NULL,
    [AwardAcceptanceStatusDate]       NVARCHAR (1000) NULL
);


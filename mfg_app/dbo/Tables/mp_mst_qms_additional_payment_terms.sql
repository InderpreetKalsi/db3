CREATE TABLE [dbo].[mp_mst_qms_additional_payment_terms] (
    [qms_additional_payment_term_id] INT           IDENTITY (1001, 1) NOT NULL,
    [supplier_company_id]            INT           NOT NULL,
    [payment_terms]                  VARCHAR (150) NULL,
    [is_default]                     BIT           CONSTRAINT [DF_mp_mst_qms_additional_payment_terms_is_default] DEFAULT ((0)) NULL,
    [is_active]                      BIT           CONSTRAINT [DF_mp_mst_qms_additional_payment_terms_is_active] DEFAULT ((1)) NULL,
    [created_date]                   DATETIME      CONSTRAINT [DF_mp_mst_qms_additional_payment_terms_created_date] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_mst_qms_additional_payment_terms] PRIMARY KEY CLUSTERED ([qms_additional_payment_term_id] ASC, [supplier_company_id] ASC) WITH (FILLFACTOR = 90)
);


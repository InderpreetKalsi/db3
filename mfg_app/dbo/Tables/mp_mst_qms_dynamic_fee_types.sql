CREATE TABLE [dbo].[mp_mst_qms_dynamic_fee_types] (
    [qms_dynamic_fee_type_id] INT           IDENTITY (101, 1) NOT NULL,
    [supplier_company_id]     INT           NOT NULL,
    [fee_type]                VARCHAR (150) NULL,
    [is_default]              BIT           CONSTRAINT [DF_mp_mst_qms_dynamic_fee_types_is_default] DEFAULT ((0)) NULL,
    [is_active]               BIT           CONSTRAINT [DF_mp_mst_qms_dynamic_fee_types_is_active] DEFAULT ((1)) NULL,
    [created_date]            DATETIME      CONSTRAINT [DF_mp_mst_qms_dynamic_fee_types_created_date] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_mst_qms_dynamic_fee_types] PRIMARY KEY CLUSTERED ([qms_dynamic_fee_type_id] ASC, [supplier_company_id] ASC) WITH (FILLFACTOR = 90)
);


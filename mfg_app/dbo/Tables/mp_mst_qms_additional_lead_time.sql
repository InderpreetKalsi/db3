CREATE TABLE [dbo].[mp_mst_qms_additional_lead_time] (
    [qms_additional_lead_time_id] INT           IDENTITY (1001, 1) NOT NULL,
    [supplier_company_id]         INT           NOT NULL,
    [lead_time]                   VARCHAR (150) NULL,
    [is_default]                  BIT           CONSTRAINT [DF_mp_mst_qms_additional_lead_time_is_default] DEFAULT ((0)) NULL,
    [is_active]                   BIT           CONSTRAINT [DF_mp_mst_qms_additional_lead_time_is_active] DEFAULT ((1)) NULL,
    [created_date]                DATETIME      CONSTRAINT [DF_mp_mst_qms_additional_lead_time_created_date] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_mst_qms_additional_lead_time] PRIMARY KEY CLUSTERED ([qms_additional_lead_time_id] ASC, [supplier_company_id] ASC) WITH (FILLFACTOR = 90)
);


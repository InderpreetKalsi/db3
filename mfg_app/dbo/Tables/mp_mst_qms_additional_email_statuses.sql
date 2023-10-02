CREATE TABLE [dbo].[mp_mst_qms_additional_email_statuses] (
    [mp_mst_qms_additional_email_status_id] INT           IDENTITY (1001, 1) NOT NULL,
    [supplier_company_id]                   INT           NOT NULL,
    [email_status]                          VARCHAR (150) NULL,
    [is_default]                            BIT           CONSTRAINT [DF_mp_mst_qms_additional_email_statuses_is_default] DEFAULT ((0)) NULL,
    [is_active]                             BIT           CONSTRAINT [DF_mp_mst_qms_additional_email_statuses_is_active] DEFAULT ((1)) NULL,
    [created_date]                          DATETIME      CONSTRAINT [DF_mp_mst_qms_additional_email_statuses_created_date] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_mst_qms_additional_email_statuses] PRIMARY KEY CLUSTERED ([mp_mst_qms_additional_email_status_id] ASC, [supplier_company_id] ASC) WITH (FILLFACTOR = 90)
);


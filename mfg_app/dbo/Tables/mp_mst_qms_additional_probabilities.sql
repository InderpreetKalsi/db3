CREATE TABLE [dbo].[mp_mst_qms_additional_probabilities] (
    [mp_mst_qms_additional_probability_id] INT           IDENTITY (1001, 1) NOT NULL,
    [supplier_company_id]                  INT           NOT NULL,
    [probability]                          VARCHAR (150) NULL,
    [is_default]                           BIT           CONSTRAINT [DF_mp_mst_qms_additional_probabilities_is_default] DEFAULT ((0)) NULL,
    [is_active]                            BIT           CONSTRAINT [DF_mp_mst_qms_additional_probabilities_is_active] DEFAULT ((1)) NULL,
    [created_date]                         DATETIME      CONSTRAINT [DF_mp_mst_qms_additional_probabilities_created_date] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_mst_qms_additional_probabilities] PRIMARY KEY CLUSTERED ([mp_mst_qms_additional_probability_id] ASC, [supplier_company_id] ASC) WITH (FILLFACTOR = 90)
);


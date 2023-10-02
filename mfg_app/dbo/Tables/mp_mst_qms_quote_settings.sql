CREATE TABLE [dbo].[mp_mst_qms_quote_settings] (
    [qms_quote_setting_id] INT           IDENTITY (1, 1) NOT NULL,
    [qms_quote_setting]    VARCHAR (150) NULL,
    [is_active]            BIT           DEFAULT ((1)) NULL,
    [sort_order]           SMALLINT      NULL,
    PRIMARY KEY CLUSTERED ([qms_quote_setting_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_mst_dashboard_guide_settings] (
    [dashboard_guide_setting_id] INT           IDENTITY (1, 1) NOT NULL,
    [dashboard_guide_name]       VARCHAR (250) NULL,
    [is_active]                  BIT           DEFAULT ((1)) NULL,
    [sort_order]                 INT           NULL,
    [guide_percentage]           INT           NULL,
    PRIMARY KEY CLUSTERED ([dashboard_guide_setting_id] ASC) WITH (FILLFACTOR = 90)
);


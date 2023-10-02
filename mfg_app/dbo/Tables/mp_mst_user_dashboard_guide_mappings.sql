CREATE TABLE [dbo].[mp_mst_user_dashboard_guide_mappings] (
    [user_dashboard_guide_mapping_id] INT IDENTITY (1, 1) NOT NULL,
    [contact_id]                      INT NOT NULL,
    [dashboard_guide_setting_id]      INT NULL,
    PRIMARY KEY CLUSTERED ([user_dashboard_guide_mapping_id] ASC, [contact_id] ASC) WITH (FILLFACTOR = 90)
);


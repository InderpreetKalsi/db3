CREATE TABLE [dbo].[mst_manager] (
    [manager_id]      INT           NOT NULL,
    [manager_name]    VARCHAR (100) NULL,
    [is_active]       BIT           NULL,
    [zoho_id]         BIGINT        NULL,
    [hubspot_user_id] BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([manager_id] ASC)
);


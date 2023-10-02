CREATE TABLE [dbo].[mp_mst_materials] (
    [material_id]        SMALLINT      IDENTITY (1, 1) NOT NULL,
    [material_name]      VARCHAR (100) NULL,
    [material_parent_id] SMALLINT      NULL,
    [industry_id]        SMALLINT      NULL,
    [publish]            BIT           NOT NULL,
    [is_active]          BIT           NULL,
    [material_name_en]   VARCHAR (200) NULL,
    CONSTRAINT [PK_mp_mst_materials] PRIMARY KEY CLUSTERED ([material_id] ASC) WITH (FILLFACTOR = 90)
);


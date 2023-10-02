CREATE TABLE [dbo].[mp_mst_part_category_type] (
    [category_type_id] SMALLINT       IDENTITY (1, 1) NOT NULL,
    [category_type]    NVARCHAR (200) NULL,
    CONSTRAINT [PK_mp_mst_part_category_type] PRIMARY KEY CLUSTERED ([category_type_id] ASC) WITH (FILLFACTOR = 90)
);


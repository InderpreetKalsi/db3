CREATE TABLE [dbo].[mp_mst_process_postprocess_mapping] (
    [id]               INT IDENTITY (101, 1) NOT NULL,
    [part_category_id] INT NULL,
    [postprocess_id]   INT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_mst_process_postprocess_mapping_part_category_id_postprocess_id]
    ON [dbo].[mp_mst_process_postprocess_mapping]([part_category_id] ASC, [postprocess_id] ASC) WITH (FILLFACTOR = 90);


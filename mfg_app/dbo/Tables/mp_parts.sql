CREATE TABLE [dbo].[mp_parts] (
    [part_id]                    BIGINT         IDENTITY (1, 1) NOT NULL,
    [part_name]                  NVARCHAR (450) NULL,
    [part_number]                NVARCHAR (450) NULL,
    [part_commodity_code]        NVARCHAR (100) NULL,
    [part_description]           NVARCHAR (MAX) NULL,
    [material_id]                SMALLINT       NULL,
    [part_qty_unit_id]           INT            NULL,
    [part_category_id]           INT            NULL,
    [status_id]                  SMALLINT       NULL,
    [company_id]                 INT            NULL,
    [contact_id]                 INT            NULL,
    [currency_id]                INT            NULL,
    [creation_date]              DATETIME       NULL,
    [modification_date]          DATETIME       NULL,
    [Post_Production_Process_id] INT            NULL,
    [part_size_unit_id]          INT            NULL,
    [width]                      FLOAT (53)     NULL,
    [height]                     FLOAT (53)     NULL,
    [depth]                      FLOAT (53)     NULL,
    [length]                     FLOAT (53)     NULL,
    [diameter]                   FLOAT (53)     NULL,
    [surface]                    FLOAT (53)     NULL,
    [volume]                     FLOAT (53)     NULL,
    [tolerance_id]               VARCHAR (50)   NULL,
    [is_child_category_selected] BIT            NULL,
    [parent_part_id]             BIGINT         NULL,
    [IsLargePart]                BIT            NULL,
    [GeometryId]                 INT            NULL,
    CONSTRAINT [PK_mp_parts] PRIMARY KEY CLUSTERED ([part_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_parts_mp_mst_currency] FOREIGN KEY ([currency_id]) REFERENCES [dbo].[mp_mst_currency] ([currency_id]),
    CONSTRAINT [FK_mp_parts_mp_mst_materials] FOREIGN KEY ([material_id]) REFERENCES [dbo].[mp_mst_materials] ([material_id]),
    CONSTRAINT [FK_mp_parts_mp_mst_part_category] FOREIGN KEY ([part_category_id]) REFERENCES [dbo].[mp_mst_part_category] ([part_category_id]),
    CONSTRAINT [FK_mp_parts_mp_mst_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[mp_mst_status] ([status_id])
);


GO
CREATE NONCLUSTERED INDEX [c_mp_parts_part_category_id]
    ON [dbo].[mp_parts]([part_category_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [nc_mp_parts_part_qty_unit_id_material_id_part_category_id]
    ON [dbo].[mp_parts]([part_qty_unit_id] ASC)
    INCLUDE([material_id], [part_category_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked id  (matching ID in mp_system_parameters) for quantity - Each, Piece, dozen, etc.  ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_parts', @level2type = N'COLUMN', @level2name = N'part_qty_unit_id';


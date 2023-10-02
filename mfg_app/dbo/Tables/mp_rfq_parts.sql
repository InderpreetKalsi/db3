CREATE TABLE [dbo].[mp_rfq_parts] (
    [rfq_part_id]                INT             IDENTITY (1, 1) NOT NULL,
    [part_id]                    BIGINT          NULL,
    [rfq_id]                     INT             NULL,
    [delivery_date]              DATETIME        NULL,
    [quantity_unit_id]           INT             NULL,
    [status_id]                  SMALLINT        NULL,
    [part_category_id]           INT             NULL,
    [created_date]               DATETIME        NULL,
    [modification_date]          DATETIME        NULL,
    [Post_Production_Process_id] INT             NULL,
    [Is_Rfq_Part_Default]        BIT             NULL,
    [ModifiedBy]                 INT             NULL,
    [min_part_quantity]          NUMERIC (18)    NULL,
    [min_part_quantity_unit]     VARCHAR (50)    NULL,
    [is_apply_delivery_date]     BIT             NULL,
    [material_id]                SMALLINT        NULL,
    [is_apply_process]           BIT             NULL,
    [is_apply_material]          BIT             NULL,
    [is_apply_post_process]      BIT             NULL,
    [is_child_category_selected] BIT             NULL,
    [is_existing_part]           BIT             NULL,
    [is_apply_parent_process]    BIT             NULL,
    [is_child_same_as_parent]    BIT             NULL,
    [parent_rfq_part_id]         INT             NULL,
    [AwardedStatusId]            INT             NULL,
    [AwardedUnit]                NUMERIC (18, 2) NULL,
    [AwardedPrice]               NUMERIC (18, 4) NULL,
    [AwardedUnitTypeId]          INT             NULL,
    CONSTRAINT [PK_mp_rfq_parts] PRIMARY KEY CLUSTERED ([rfq_part_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_parts_mp_parts] FOREIGN KEY ([part_id]) REFERENCES [dbo].[mp_parts] ([part_id]),
    CONSTRAINT [FK_mp_rfq_parts_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
CREATE NONCLUSTERED INDEX [nc_mp_rfq_parts_part_id_rfq_id]
    ON [dbo].[mp_rfq_parts]([part_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_parts_01]
    ON [dbo].[mp_rfq_parts]([rfq_id] ASC)
    INCLUDE([part_id], [Post_Production_Process_id], [Is_Rfq_Part_Default]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_parts_Is_Rfq_Part_Default_status_id]
    ON [dbo].[mp_rfq_parts]([Is_Rfq_Part_Default] ASC, [status_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked id  (matching ID in mp_system_parameters) for quantity - Each, Piece, dozen, etc.  ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_parts', @level2type = N'COLUMN', @level2name = N'quantity_unit_id';


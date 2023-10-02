CREATE TABLE [dbo].[mp_rfq_part_quantity] (
    [rfq_part_quantity_id] INT             IDENTITY (1, 1) NOT NULL,
    [rfq_part_id]          INT             NULL,
    [part_qty]             NUMERIC (18, 3) NULL,
    [quantity_level]       SMALLINT        NULL,
    [ModifiedBy]           INT             NULL,
    [is_deleted]           BIT             DEFAULT ((0)) NOT NULL,
    [CreatedOn]            DATETIME        DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_rfq_part_quantity] PRIMARY KEY CLUSTERED ([rfq_part_quantity_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_part_quantity_mp_rfq_parts] FOREIGN KEY ([rfq_part_id]) REFERENCES [dbo].[mp_rfq_parts] ([rfq_part_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_part_quantity_01]
    ON [dbo].[mp_rfq_part_quantity]([rfq_part_id] ASC)
    INCLUDE([part_qty]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This will indicate the level of the quantity like Quantity1, Quantity2…etc.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_part_quantity', @level2type = N'COLUMN', @level2name = N'quantity_level';


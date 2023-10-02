CREATE TABLE [dbo].[mp_mst_scheduler_type] (
    [scheduler_type_id]        SMALLINT     IDENTITY (1, 1) NOT NULL,
    [scheduler_type_name]      VARCHAR (75) NOT NULL,
    [scheduler_category_id]    SMALLINT     NULL,
    [parent_scheduler_type_id] SMALLINT     NULL,
    [is_real_time]             BIT          DEFAULT ((0)) NOT NULL,
    [is_scheduled]             BIT          DEFAULT ((0)) NOT NULL,
    [is_deleted]               BIT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_mst_scheduler_type] PRIMARY KEY CLUSTERED ([scheduler_type_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_mst_scheduler_type_mp_mst_scheduler_category] FOREIGN KEY ([scheduler_category_id]) REFERENCES [dbo].[mp_mst_scheduler_category] ([scheduler_category_id]),
    CONSTRAINT [FK_mp_mst_scheduler_type_mp_mst_scheduler_type] FOREIGN KEY ([parent_scheduler_type_id]) REFERENCES [dbo].[mp_mst_scheduler_type] ([scheduler_type_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table links job categories to job types', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Scheduler Type', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type', @level2type = N'COLUMN', @level2name = N'scheduler_type_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Scheduler category linked to mp_mst_scheduler_category table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type', @level2type = N'COLUMN', @level2name = N'scheduler_category_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Parent Scheduler type from same table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type', @level2type = N'COLUMN', @level2name = N'parent_scheduler_type_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Notify instantly on action', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type', @level2type = N'COLUMN', @level2name = N'is_real_time';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Include in daily summary message/email', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type', @level2type = N'COLUMN', @level2name = N'is_scheduled';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Do not notify', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_type', @level2type = N'COLUMN', @level2name = N'is_deleted';


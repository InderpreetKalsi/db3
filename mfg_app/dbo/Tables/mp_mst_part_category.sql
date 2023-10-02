CREATE TABLE [dbo].[mp_mst_part_category] (
    [part_category_id]          INT            IDENTITY (1, 1) NOT NULL,
    [industry_id]               SMALLINT       NULL,
    [category_type_id]          SMALLINT       NULL,
    [parent_part_category_id]   INT            NULL,
    [status_id]                 SMALLINT       NULL,
    [discipline_code]           VARCHAR (100)  NULL,
    [discipline_name]           VARCHAR (100)  NULL,
    [discipline_desc]           NVARCHAR (300) NULL,
    [level]                     SMALLINT       NULL,
    [item]                      BIT            NOT NULL,
    [l1_discipline_id]          INT            NULL,
    [ShowPartSizingComponent]   BIT            DEFAULT ((0)) NULL,
    [ShowQuestionsOnPartDrawer] BIT            DEFAULT ((0)) NULL,
    [SortOrder]                 SMALLINT       NULL,
    CONSTRAINT [PK_mp_mst_part_category] PRIMARY KEY CLUSTERED ([part_category_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_mst_part_category_mp_mst_part_category] FOREIGN KEY ([parent_part_category_id]) REFERENCES [dbo].[mp_mst_part_category] ([part_category_id]),
    CONSTRAINT [FK_mp_mst_part_category_mp_mst_part_category_type] FOREIGN KEY ([category_type_id]) REFERENCES [dbo].[mp_mst_part_category_type] ([category_type_id]),
    CONSTRAINT [FK_mp_mst_part_category_mp_mst_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[mp_mst_status] ([status_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_NONCLUSTERED_mp_mst_part_category_20180905]
    ON [dbo].[mp_mst_part_category]([parent_part_category_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_NONCLUSTERED_mp_mst_part_category_20180905_02]
    ON [dbo].[mp_mst_part_category]([status_id] ASC, [discipline_name] ASC)
    INCLUDE([parent_part_category_id]) WITH (FILLFACTOR = 90);


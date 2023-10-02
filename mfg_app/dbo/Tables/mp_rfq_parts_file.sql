CREATE TABLE [dbo].[mp_rfq_parts_file] (
    [rfq_part_file_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_part_id]      INT      NULL,
    [file_id]          INT      NULL,
    [creation_date]    DATETIME NULL,
    [status_id]        INT      NULL,
    [is_primary_file]  BIT      CONSTRAINT [DF__mp_rfq_pa__is_su__12C8C788] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_rfq_parts_file] PRIMARY KEY CLUSTERED ([rfq_part_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_parts_file_mp_rfq_parts] FOREIGN KEY ([rfq_part_id]) REFERENCES [dbo].[mp_rfq_parts] ([rfq_part_id])
);


GO
CREATE NONCLUSTERED INDEX [nc_mp_rfq_parts_file_rfq_part_id_is_primary_file]
    ON [dbo].[mp_rfq_parts_file]([rfq_part_id] ASC, [is_primary_file] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'File information will be stored in "mp_special_files" table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_parts_file', @level2type = N'COLUMN', @level2name = N'file_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This indicate the part file is original part file or other supporting files for that part', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_parts_file', @level2type = N'COLUMN', @level2name = N'is_primary_file';


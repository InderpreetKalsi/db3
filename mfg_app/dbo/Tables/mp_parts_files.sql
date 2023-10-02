CREATE TABLE [dbo].[mp_parts_files] (
    [parts_file_id]   INT    IDENTITY (1, 1) NOT NULL,
    [parts_id]        BIGINT NULL,
    [file_id]         INT    NULL,
    [is_primary_file] BIT    NULL,
    CONSTRAINT [PK_mp_parts_files] PRIMARY KEY CLUSTERED ([parts_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_parts_files_mp_parts] FOREIGN KEY ([parts_id]) REFERENCES [dbo].[mp_parts] ([part_id]),
    CONSTRAINT [FK_mp_parts_files_mp_special_files] FOREIGN KEY ([file_id]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table will holds the mapping between Parts and their files.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_parts_files';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'File information will be stored in "mp_special_files" table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_parts_files', @level2type = N'COLUMN', @level2name = N'file_id';


CREATE TABLE [dbo].[mp_rfq_other_files] (
    [rfq_other_file_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]            INT      NULL,
    [file_id]           INT      NULL,
    [creation_date]     DATETIME NULL,
    [status_id]         INT      NULL,
    CONSTRAINT [PK_mp_rfq_other_files] PRIMARY KEY CLUSTERED ([rfq_other_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_other_files_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id]),
    CONSTRAINT [FK_mp_rfq_other_files_mp_special_files] FOREIGN KEY ([file_id]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


GO
ALTER TABLE [dbo].[mp_rfq_other_files] NOCHECK CONSTRAINT [FK_mp_rfq_other_files_mp_rfq];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'File information will be stored in "mp_special_files" table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_other_files', @level2type = N'COLUMN', @level2name = N'file_id';


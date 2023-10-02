CREATE TABLE [dbo].[mp_qms_quote_other_files] (
    [qms_quote_other_files_id] INT      IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]             INT      NULL,
    [file_id]                  INT      NULL,
    [creation_date]            DATETIME NULL,
    [status_id]                INT      NULL,
    CONSTRAINT [PK_mp_qms_quote_other_files] PRIMARY KEY CLUSTERED ([qms_quote_other_files_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_other_files_mp_qms_quotes] FOREIGN KEY ([qms_quote_id]) REFERENCES [dbo].[mp_qms_quotes] ([qms_quote_id]),
    CONSTRAINT [FK_mp_qms_quote_other_files_mp_special_files] FOREIGN KEY ([file_id]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


GO
ALTER TABLE [dbo].[mp_qms_quote_other_files] NOCHECK CONSTRAINT [FK_mp_qms_quote_other_files_mp_qms_quotes];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'File information will be stored in "mp_special_files" table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_qms_quote_other_files', @level2type = N'COLUMN', @level2name = N'file_id';


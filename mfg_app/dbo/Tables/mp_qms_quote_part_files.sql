CREATE TABLE [dbo].[mp_qms_quote_part_files] (
    [qms_quote_part_file_id] INT IDENTITY (1, 1) NOT NULL,
    [qms_quote_part_id]      INT NOT NULL,
    [file_id]                INT NULL,
    [status_id]              INT NULL,
    [is_primary]             BIT CONSTRAINT [DF_mp_qms_quote_part_files_is_primary] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_qms_quote_part_files] PRIMARY KEY CLUSTERED ([qms_quote_part_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_part_files_mp_qms_quote_parts] FOREIGN KEY ([qms_quote_part_id]) REFERENCES [dbo].[mp_qms_quote_parts] ([qms_quote_part_id])
);


GO
ALTER TABLE [dbo].[mp_qms_quote_part_files] NOCHECK CONSTRAINT [FK_mp_qms_quote_part_files_mp_qms_quote_parts];


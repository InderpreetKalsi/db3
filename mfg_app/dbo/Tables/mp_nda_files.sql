CREATE TABLE [dbo].[mp_nda_files] (
    [nda_file_id] INT IDENTITY (1, 1) NOT NULL,
    [nda_id]      INT NOT NULL,
    [file_id]     INT NOT NULL,
    CONSTRAINT [PK_mp_nda_files] PRIMARY KEY CLUSTERED ([nda_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_nda_files_mp_accepted_nda1] FOREIGN KEY ([nda_id]) REFERENCES [dbo].[mp_accepted_nda] ([accepted_nda_id]),
    CONSTRAINT [FK_mp_nda_files_mp_special_files] FOREIGN KEY ([file_id]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


GO
ALTER TABLE [dbo].[mp_nda_files] NOCHECK CONSTRAINT [FK_mp_nda_files_mp_accepted_nda1];


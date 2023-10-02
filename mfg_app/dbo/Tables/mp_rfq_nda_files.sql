CREATE TABLE [dbo].[mp_rfq_nda_files] (
    [rfq_nda_file_id]     INT IDENTITY (1, 1) NOT NULL,
    [rfq_accepted_nda_id] INT NULL,
    [file_id]             INT NULL,
    CONSTRAINT [PK_mp_rfq_nda_files] PRIMARY KEY CLUSTERED ([rfq_nda_file_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_nda_files_mp_rfq_accepted_nda] FOREIGN KEY ([rfq_accepted_nda_id]) REFERENCES [dbo].[mp_rfq_accepted_nda] ([rfq_accepted_nda_id])
);


GO
ALTER TABLE [dbo].[mp_rfq_nda_files] NOCHECK CONSTRAINT [FK_mp_rfq_nda_files_mp_rfq_accepted_nda];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table holds the RFQ Custom NDA added by buyer from NDA Verbage section', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_nda_files';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'File information will be stored in "mp_special_files" table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_nda_files', @level2type = N'COLUMN', @level2name = N'file_id';


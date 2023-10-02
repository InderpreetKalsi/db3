CREATE TABLE [dbo].[mp_special_files] (
    [FILE_ID]                  INT            IDENTITY (1, 1) NOT NULL,
    [FILE_NAME]                VARCHAR (MAX)  NULL,
    [CONT_ID]                  INT            NULL,
    [COMP_ID]                  INT            NULL,
    [IS_DELETED]               BIT            NOT NULL,
    [FILETYPE_ID]              SMALLINT       NOT NULL,
    [CREATION_DATE]            DATETIME       NOT NULL,
    [Imported_Location]        NVARCHAR (50)  NULL,
    [parent_file_id]           INT            NULL,
    [Legacy_file_id]           INT            NULL,
    [file_title]               NVARCHAR (150) NULL,
    [file_caption]             NVARCHAR (400) NULL,
    [file_path]                VARCHAR (500)  NULL,
    [s3_found_status]          BIT            NULL,
    [is_processed]             BIT            CONSTRAINT [DF__mp_specia__is_pr__589C25F3] DEFAULT ((0)) NULL,
    [sort_order]               INT            NULL,
    [ReshapeFileProcessedURL]  VARCHAR (2000) NULL,
    [IsFileProcessedByReshape] BIT            NULL,
    [ReshapeProjectUid]        VARCHAR (1000) NULL,
    [ReshapeFileUid]           VARCHAR (1000) NULL,
    CONSTRAINT [PK_mp_special_files] PRIMARY KEY CLUSTERED ([FILE_ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_special_files_mp_mst_filetype] FOREIGN KEY ([FILETYPE_ID]) REFERENCES [dbo].[mp_mst_filetype] ([filetype_id])
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_special_files_FILETYPE_ID]
    ON [dbo].[mp_special_files]([FILETYPE_ID] ASC, [CONT_ID] ASC)
    INCLUDE([FILE_NAME]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_special_files_IS_DELETED_FILETYPE_ID]
    ON [dbo].[mp_special_files]([IS_DELETED] ASC, [FILETYPE_ID] ASC)
    INCLUDE([FILE_NAME], [COMP_ID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_special_files_COMP_Id_FILETYPE_ID]
    ON [dbo].[mp_special_files]([COMP_ID] ASC, [FILETYPE_ID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'File associated to a company - specifically profile and file vault related.  A container for company information at both a company and a contact level.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_special_files';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Logical file deletion flag.  Physical deletes -never- occur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_special_files', @level2type = N'COLUMN', @level2name = N'IS_DELETED';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This location holds the information to indicate that from whicl table for legacy system data has been pulled', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_special_files', @level2type = N'COLUMN', @level2name = N'Imported_Location';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This holds the ID from the legacy database', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_special_files', @level2type = N'COLUMN', @level2name = N'Legacy_file_id';


CREATE TABLE [dbo].[mp_s3_process_files] (
    [FILE_ID]           INT            IDENTITY (1, 1) NOT NULL,
    [FILE_NAME]         VARCHAR (510)  NULL,
    [CONT_ID]           INT            NULL,
    [COMP_ID]           INT            NULL,
    [IS_DELETED]        BIT            NOT NULL,
    [FILETYPE_ID]       SMALLINT       NOT NULL,
    [CREATION_DATE]     DATETIME       NOT NULL,
    [Imported_Location] NVARCHAR (50)  NULL,
    [parent_file_id]    INT            NULL,
    [Legacy_file_id]    INT            NULL,
    [file_title]        NVARCHAR (150) NULL,
    [file_caption]      NVARCHAR (400) NULL,
    [file_path]         VARCHAR (500)  NULL,
    [s3_found_status]   BIT            NULL,
    [is_processed]      BIT            NULL
);


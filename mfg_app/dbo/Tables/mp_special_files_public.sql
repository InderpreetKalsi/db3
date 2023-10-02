CREATE TABLE [dbo].[mp_special_files_public] (
    [FILE_ID]         INT           NOT NULL,
    [FILE_NAME]       VARCHAR (MAX) NULL,
    [CONT_ID]         INT           NULL,
    [COMP_ID]         INT           NULL,
    [IS_DELETED]      BIT           NOT NULL,
    [FILETYPE_ID]     SMALLINT      NOT NULL,
    [CREATION_DATE]   DATETIME      NOT NULL,
    [s3_found_status] INT           NULL,
    [is_processed]    INT           NULL
);


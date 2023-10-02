CREATE TABLE [dbo].[s3_process_files_extra] (
    [s3_process_file_id] INT            NOT NULL,
    [file_name]          NVARCHAR (500) NULL,
    [legacy_file_id]     INT            NULL,
    [src_folder]         NVARCHAR (500) NULL,
    [dest_folder]        NVARCHAR (500) NULL,
    [importedDate]       DATETIME       NULL,
    [FileType_id]        SMALLINT       NULL,
    [Process_filename]   NVARCHAR (500) NULL,
    [Special_file_id]    INT            NULL,
    [Is_legacy_exist]    BIT            NULL
);


CREATE TABLE [dbo].[s3_process_files1] (
    [s3_process_file_id] INT            NOT NULL,
    [file_name]          NVARCHAR (500) NULL,
    [legacy_file_id]     INT            NULL,
    [src_folder]         NVARCHAR (500) NULL,
    [dest_folder]        NVARCHAR (500) NULL
);


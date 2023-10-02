CREATE TYPE [dbo].[tbl_s3_upload_Process] AS TABLE (
    [file_name]      NVARCHAR (1000) NULL,
    [legacy_file_id] INT             NULL,
    [src_folder]     NVARCHAR (1000) NULL,
    [dest_folder]    NVARCHAR (1000) NULL);


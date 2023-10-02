CREATE TYPE [dbo].[tbl_s3_upload_Process_NewFileNames] AS TABLE (
    [FileId]    INT             NULL,
    [file_name] NVARCHAR (1000) NULL,
    [found]     BIT             NULL);


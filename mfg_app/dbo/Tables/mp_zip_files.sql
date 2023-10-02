CREATE TABLE [dbo].[mp_zip_files] (
    [zip_file_id] INT            IDENTITY (1, 1) NOT NULL,
    [file_name]   NVARCHAR (250) NOT NULL,
    [rfq_id]      INT            NULL,
    [part_id]     INT            NULL,
    [is_active]   BIT            CONSTRAINT [DF_mp_zip_files_is_active] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_mp_zip_files] PRIMARY KEY CLUSTERED ([zip_file_id] ASC) WITH (FILLFACTOR = 90)
);


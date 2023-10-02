CREATE TABLE [dbo].[mp_mst_filetype] (
    [filetype_id] SMALLINT       IDENTITY (1, 1) NOT NULL,
    [description] NVARCHAR (200) NOT NULL,
    [Source_Loc]  NVARCHAR (50)  NULL,
    CONSTRAINT [PK_mp_mst_filetype] PRIMARY KEY CLUSTERED ([filetype_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Maintain the types of files like Logo file, personal picture, company infor file etc....', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_filetype';


CREATE TABLE [dbo].[mp_mst_continent] (
    [continent_id]      SMALLINT       IDENTITY (1, 1) NOT NULL,
    [continent_name]    NVARCHAR (100) NOT NULL,
    [classification]    NVARCHAR (50)  NULL,
    [classification_id] SMALLINT       NULL,
    CONSTRAINT [PK_mp_mst_continent] PRIMARY KEY CLUSTERED ([continent_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This column link to "mp_mst_continent_classification" to indicate the continent under specific classification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_continent', @level2type = N'COLUMN', @level2name = N'classification_id';


CREATE TABLE [dbo].[mp_mst_industries] (
    [industry_id]  SMALLINT     IDENTITY (1, 1) NOT NULL,
    [industry_key] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_mp_mst_industries] PRIMARY KEY CLUSTERED ([industry_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Industry List (ex Manufacturing, Textile, ...)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_industries';


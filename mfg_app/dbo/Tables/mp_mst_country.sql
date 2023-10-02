CREATE TABLE [dbo].[mp_mst_country] (
    [country_id]                  SMALLINT      IDENTITY (1, 1) NOT NULL,
    [country_name]                NVARCHAR (50) NOT NULL,
    [code_telephone]              NVARCHAR (20) NULL,
    [country_lang]                NVARCHAR (8)  NULL,
    [iso_code]                    NVARCHAR (4)  NULL,
    [continent_id]                INT           NULL,
    [territory_classification_id] INT           NULL,
    CONSTRAINT [PK_mp_mst_country] PRIMARY KEY CLUSTERED ([country_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Country definition', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_country';


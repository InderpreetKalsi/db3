CREATE TABLE [dbo].[mp_mst_territory_classification] (
    [territory_classification_id]       SMALLINT       IDENTITY (1, 1) NOT NULL,
    [territory_classification_name]     NVARCHAR (100) NULL,
    [territory_classification_code]     VARCHAR (10)   NULL,
    [territory_classification_DispName] VARCHAR (50)   NULL,
    [sort_order]                        SMALLINT       NULL,
    CONSTRAINT [PK_mp_mst_territory_classification] PRIMARY KEY CLUSTERED ([territory_classification_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[hubspot_mst_territory_classification] (
    [territory_classification_id]       SMALLINT       IDENTITY (1, 1) NOT NULL,
    [territory_classification_name]     NVARCHAR (100) NULL,
    [territory_classification_code]     VARCHAR (10)   NULL,
    [territory_classification_DispName] VARCHAR (50)   NULL,
    CONSTRAINT [PK_hubspot_mst_territory_classification] PRIMARY KEY CLUSTERED ([territory_classification_id] ASC) WITH (FILLFACTOR = 80)
);


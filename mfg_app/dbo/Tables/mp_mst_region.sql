CREATE TABLE [dbo].[mp_mst_region] (
    [REGION_ID]   SMALLINT       IDENTITY (1, 1) NOT NULL,
    [REGION_NAME] NVARCHAR (200) NOT NULL,
    [COUNTRY_ID]  SMALLINT       NOT NULL,
    CONSTRAINT [PK_mp_mst_region] PRIMARY KEY CLUSTERED ([REGION_ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_mst_region_mp_mst_country] FOREIGN KEY ([COUNTRY_ID]) REFERENCES [dbo].[mp_mst_country] ([country_id])
);


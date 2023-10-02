CREATE TABLE [dbo].[mp_mst_scheduler_category] (
    [scheduler_category_id]   SMALLINT     IDENTITY (1, 1) NOT NULL,
    [scheduler_category_name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_mp_scheduler_category] PRIMARY KEY CLUSTERED ([scheduler_category_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Stores the types of notification like Daily Summary/System Email etc.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_scheduler_category';


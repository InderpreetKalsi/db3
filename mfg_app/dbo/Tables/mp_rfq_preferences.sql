CREATE TABLE [dbo].[mp_rfq_preferences] (
    [rfq_preferences_id]                 INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                             INT      NULL,
    [rfq_pref_manufacturing_location_id] SMALLINT NULL,
    [ModifiedBy]                         INT      NULL,
    CONSTRAINT [PK_mp_rfq_preferences] PRIMARY KEY CLUSTERED ([rfq_preferences_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_preferences_mp_mst_territory_classification] FOREIGN KEY ([rfq_pref_manufacturing_location_id]) REFERENCES [dbo].[mp_mst_territory_classification] ([territory_classification_id]),
    CONSTRAINT [FK_mp_rfq_preferences_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_preferences_01]
    ON [dbo].[mp_rfq_preferences]([rfq_id] ASC)
    INCLUDE([rfq_pref_manufacturing_location_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_preferences_rfq_pref_manufacturing_location_id_01]
    ON [dbo].[mp_rfq_preferences]([rfq_pref_manufacturing_location_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


CREATE TABLE [dbo].[mp_lead_message_mapping] (
    [id]         INT IDENTITY (100, 1) NOT NULL,
    [lead_id]    INT NULL,
    [message_id] INT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_lead_message_mapping_lead_id_message_id]
    ON [dbo].[mp_lead_message_mapping]([lead_id] ASC, [message_id] ASC) WITH (FILLFACTOR = 90);


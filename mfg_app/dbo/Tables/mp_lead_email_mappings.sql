CREATE TABLE [dbo].[mp_lead_email_mappings] (
    [lead_id]               INT NULL,
    [lead_email_message_id] INT NULL,
    [id]                    INT IDENTITY (100, 1) NOT NULL,
    CONSTRAINT [PK_mp_lead_email_mappings] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_lead_email_mappings_mp_lead] FOREIGN KEY ([lead_id]) REFERENCES [dbo].[mp_lead] ([lead_id]),
    CONSTRAINT [FK_mp_lead_email_mappings_mp_lead_emails] FOREIGN KEY ([lead_email_message_id]) REFERENCES [dbo].[mp_lead_emails] ([lead_email_message_id])
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_lead_email_mappings_lead_id_lead_email_message_id]
    ON [dbo].[mp_lead_email_mappings]([lead_id] ASC, [lead_email_message_id] ASC) WITH (FILLFACTOR = 90);


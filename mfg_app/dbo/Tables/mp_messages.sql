CREATE TABLE [dbo].[mp_messages] (
    [message_id]                  INT             IDENTITY (1, 1) NOT NULL,
    [rfq_id]                      INT             NULL,
    [message_type_id]             SMALLINT        NULL,
    [message_hierarchy]           INT             NULL,
    [message_subject]             NVARCHAR (1000) NULL,
    [message_descr]               NVARCHAR (MAX)  NULL,
    [message_date]                DATETIME        NOT NULL,
    [from_cont]                   INT             NULL,
    [to_cont]                     INT             NULL,
    [message_read]                BIT             NOT NULL,
    [message_sent]                BIT             NOT NULL,
    [read_date]                   DATETIME        NULL,
    [message_status_id_recipient] SMALLINT        NOT NULL,
    [message_status_id_author]    SMALLINT        NOT NULL,
    [expiration_date]             DATETIME        NULL,
    [trash]                       BIT             NOT NULL,
    [trash_date]                  DATETIME        NULL,
    [from_trash]                  BIT             NOT NULL,
    [from_trash_date]             DATETIME        NULL,
    [LegacyData_import_Date]      DATETIME        NULL,
    [real_from_cont_id]           INT             DEFAULT ((0)) NOT NULL,
    [is_last_message]             BIT             DEFAULT ((0)) NOT NULL,
    [is_nda_required]             BIT             NULL,
    [is_external_nda_accepted]    BIT             NULL,
    [is_notification_closed]      BIT             NULL,
    CONSTRAINT [PK_mp_messages] PRIMARY KEY CLUSTERED ([message_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_messages_mp_contacts] FOREIGN KEY ([from_cont]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_messages_mp_contacts1] FOREIGN KEY ([to_cont]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_messages_mp_mst_message_status] FOREIGN KEY ([message_status_id_recipient]) REFERENCES [dbo].[mp_mst_message_status] ([message_status_id]),
    CONSTRAINT [FK_mp_messages_mp_mst_message_status1] FOREIGN KEY ([message_status_id_author]) REFERENCES [dbo].[mp_mst_message_status] ([message_status_id]),
    CONSTRAINT [FK_mp_messages_mp_mst_message_types] FOREIGN KEY ([message_type_id]) REFERENCES [dbo].[mp_mst_message_types] ([message_type_id]),
    CONSTRAINT [FK_mp_messages_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
CREATE NONCLUSTERED INDEX [NC_IDX_mp_messages_rfq_id_message_type_id_from_cont_to_cont_trash]
    ON [dbo].[mp_messages]([rfq_id] ASC, [message_type_id] ASC, [from_cont] ASC, [trash] ASC)
    INCLUDE([message_hierarchy], [message_subject], [message_descr], [message_date], [message_read], [message_sent], [read_date], [message_status_id_recipient], [message_status_id_author], [expiration_date], [trash_date], [from_trash], [from_trash_date], [LegacyData_import_Date], [real_from_cont_id], [is_last_message]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked RFQ id', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'rfq_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'message type id (linked to SP_MESSAGE_TYPE)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_type_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Parent Message ID to maintain message hirerchy', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_hierarchy';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Subject.  For some messages in the system, the user cannot change subject or description', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_subject';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Message Description - the text inside a message.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_descr';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'creation date', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'contact id, message author', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'from_cont';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'contact id, message recipient', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'to_cont';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Flag = 1 when the message has been read/opened on the site', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_read';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Flag=1 when email message sent to recipient', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_sent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This couldbe null in case of Email', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'read_date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Linked to mp_mst_message_status', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_status_id_recipient';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_mst_message_status', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'message_status_id_author';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This column is used for identifying an imported legacy records', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'LegacyData_import_Date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'the real message author identifier (0 when message author identifier is held in column FROM_CONT)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'real_from_cont_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'flag = 1 when the message is the last one for a contact and a message type.  In Enterprise, a supplier sends a quote then sends another quote for the same rfq.  In fact, a supplier can quote many times - we only care about the last quote.  Previous quoets are considered dead.  When looking at quotes, we should always watch for ""IS_LAST_MESSAGE = 1.""  This is kept up to date via a trigger.  Used in both marketplace and enterprise.  Note - In Marketplace, ""Quote Retracted"" is used to makr this also.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_messages', @level2type = N'COLUMN', @level2name = N'is_last_message';


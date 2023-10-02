CREATE TABLE [dbo].[mp_scheduled_job] (
    [scheduled_id]      INT      IDENTITY (1, 1) NOT NULL,
    [scheduler_type_id] SMALLINT NOT NULL,
    [contact_id]        INT      NOT NULL,
    [is_real_time]      BIT      DEFAULT ((0)) NOT NULL,
    [is_scheduled]      BIT      DEFAULT ((0)) NOT NULL,
    [is_deleted]        BIT      DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_scheduled_job] PRIMARY KEY CLUSTERED ([scheduled_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_scheduled_job_mp_contacts] FOREIGN KEY ([contact_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_scheduled_job_mp_mst_scheduler_type] FOREIGN KEY ([scheduler_type_id]) REFERENCES [dbo].[mp_mst_scheduler_type] ([scheduler_type_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Holds the user notifications'' preferences, e.g., New Quotes  Award Confirmations, Ratings to Perform, Newsletter... and how each notification is processed (sent immediately or at scheduled time).  Only one schedule is defined for all notifications, although the DB structure allows for one schedule per notification.  This is primarily only used for email notifications.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_scheduled_job';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'notification type (e.g., newsletter, ratings to perform, new quotes...)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_scheduled_job', @level2type = N'COLUMN', @level2name = N'scheduler_type_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'notification recipient', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_scheduled_job', @level2type = N'COLUMN', @level2name = N'contact_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'True when a notification must be sent almost immediately when activity occurs, false otherwise.  While this looks like real time notification this is "almost real time" - it is guaranteed to be sent out within the hour.  No stronger guarantee is made.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_scheduled_job', @level2type = N'COLUMN', @level2name = N'is_real_time';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'True when a notification must be sent at a scheduled time after an activity occured, false otherwise.  This is for any email type that is a scheduled email as opposed to real time.  IE:  If the user wishes to see their saved search results every day at 4:00 PM that is queued up and sent as a  job at 4:00 PM.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_scheduled_job', @level2type = N'COLUMN', @level2name = N'is_scheduled';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'true when a notification must not be sent, false otherwise', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_scheduled_job', @level2type = N'COLUMN', @level2name = N'is_deleted';


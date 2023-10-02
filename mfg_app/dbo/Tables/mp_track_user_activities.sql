CREATE TABLE [dbo].[mp_track_user_activities] (
    [user_activity_id] INT            IDENTITY (1, 1) NOT NULL,
    [contact_id]       INT            NOT NULL,
    [activity_id]      INT            NOT NULL,
    [activity_date]    DATETIME       DEFAULT (getutcdate()) NULL,
    [Value]            VARCHAR (100)  NULL,
    [Comment]          VARCHAR (1000) NULL,
    [ScheduledDate]    DATETIME       NULL,
    PRIMARY KEY CLUSTERED ([user_activity_id] ASC, [contact_id] ASC, [activity_id] ASC) WITH (FILLFACTOR = 90),
    FOREIGN KEY ([activity_id]) REFERENCES [dbo].[mp_mst_activities] ([activity_id])
);


GO
CREATE NONCLUSTERED INDEX [Idx_[mp_track_user_activities_activity_id_Value_activity_date]
    ON [dbo].[mp_track_user_activities]([activity_id] ASC, [Value] ASC)
    INCLUDE([activity_date]) WITH (FILLFACTOR = 90);


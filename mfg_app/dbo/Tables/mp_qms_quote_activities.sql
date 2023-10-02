CREATE TABLE [dbo].[mp_qms_quote_activities] (
    [activity_id]           INT      IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]          INT      NOT NULL,
    [qms_quote_activity_id] INT      NOT NULL,
    [activity_date]         DATETIME DEFAULT (getdate()) NOT NULL,
    [created_by]            INT      NOT NULL,
    CONSTRAINT [PK_mp_qms_quote_activities] PRIMARY KEY CLUSTERED ([qms_quote_id] ASC, [activity_id] ASC, [qms_quote_activity_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_activities_mp_mst_qms_quote_activities] FOREIGN KEY ([qms_quote_activity_id]) REFERENCES [dbo].[mp_mst_qms_quote_activities] ([qms_quote_activity_id]),
    CONSTRAINT [FK_mp_qms_quote_activities_mp_qms_quotes] FOREIGN KEY ([qms_quote_id]) REFERENCES [dbo].[mp_qms_quotes] ([qms_quote_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


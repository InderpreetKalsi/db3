CREATE TABLE [dbo].[mp_qms_quote_lead_times] (
    [qms_quote_lead_time_id] INT            IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]           INT            NOT NULL,
    [lead_time_id]           INT            NOT NULL,
    [lead_time_value]        NUMERIC (5, 1) NULL,
    [lead_time_range]        VARCHAR (50)   NULL,
    CONSTRAINT [PK_mp_qms_quote_lead_times] PRIMARY KEY CLUSTERED ([qms_quote_lead_time_id] ASC, [qms_quote_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_lead_times_mp_qms_quotes] FOREIGN KEY ([qms_quote_id]) REFERENCES [dbo].[mp_qms_quotes] ([qms_quote_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


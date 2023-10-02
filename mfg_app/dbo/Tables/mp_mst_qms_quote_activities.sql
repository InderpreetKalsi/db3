CREATE TABLE [dbo].[mp_mst_qms_quote_activities] (
    [qms_quote_activity_id] INT           IDENTITY (101, 1) NOT NULL,
    [qms_quote_activity]    VARCHAR (150) NOT NULL,
    [is_active]             BIT           DEFAULT ((1)) NULL,
    CONSTRAINT [PK_mp_mst_qms_quote_activities] PRIMARY KEY CLUSTERED ([qms_quote_activity_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_rfq_Status_history] (
    [rfq_status_history_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                INT      NULL,
    [status_id]             SMALLINT NULL,
    [status_date]           DATETIME NULL,
    CONSTRAINT [PK_mp_rfq_Status_history] PRIMARY KEY CLUSTERED ([rfq_status_history_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[hubspot_sync_logs] (
    [sync_log_id]                      INT      IDENTITY (1, 1) NOT NULL,
    [hubspot_module_id]                INT      NOT NULL,
    [sync_date_time]                   DATETIME NULL,
    [SyncType]                         INT      NULL,
    [OperationType]                    INT      NULL,
    [sync_date_time_IST]               DATETIME NULL,
    [sync_unix_timestamp_milliseconds] BIGINT   NULL,
    CONSTRAINT [PK_hubspot_sync_logs] PRIMARY KEY CLUSTERED ([sync_log_id] ASC) WITH (FILLFACTOR = 80)
);


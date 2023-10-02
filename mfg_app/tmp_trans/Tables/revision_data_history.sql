CREATE TABLE [tmp_trans].[revision_data_history] (
    [data_history_id] BIGINT         NULL,
    [field]           NVARCHAR (400) NULL,
    [oldvalue]        NVARCHAR (MAX) NULL,
    [newvalue]        NVARCHAR (MAX) NULL,
    [creation_date]   DATETIME       NULL,
    [userid]          INT            NULL,
    [tablename]       NVARCHAR (100) NULL,
    [is_processed]    BIT            NULL,
    [processed_date]  DATETIME       NULL
);


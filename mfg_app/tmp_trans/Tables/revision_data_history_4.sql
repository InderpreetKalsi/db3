CREATE TABLE [tmp_trans].[revision_data_history_4] (
    [data_history_id] INT NULL,
    [rfq_id]          INT NULL,
    [userid]          INT NULL
);


GO
CREATE CLUSTERED INDEX [ix_revision_data_history_4_data_history_id]
    ON [tmp_trans].[revision_data_history_4]([data_history_id] ASC) WITH (FILLFACTOR = 90);


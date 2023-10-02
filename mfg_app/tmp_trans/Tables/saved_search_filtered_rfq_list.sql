CREATE TABLE [tmp_trans].[saved_search_filtered_rfq_list] (
    [rfq_id] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_saved_search_filtered_rfq_list]
    ON [tmp_trans].[saved_search_filtered_rfq_list]([rfq_id] ASC) WITH (FILLFACTOR = 90);


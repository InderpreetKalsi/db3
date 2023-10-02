CREATE TABLE [tmp_trans].[saved_search_rfq_list_for_parts_search] (
    [rfq_id] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_saved_search_rfq_list_for_parts_search]
    ON [tmp_trans].[saved_search_rfq_list_for_parts_search]([rfq_id] ASC) WITH (FILLFACTOR = 90);


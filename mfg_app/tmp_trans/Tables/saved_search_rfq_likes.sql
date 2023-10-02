CREATE TABLE [tmp_trans].[saved_search_rfq_likes] (
    [rfq_id]      INT NULL,
    [is_rfq_like] BIT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_saved_search_saved_search_rfq_likes]
    ON [tmp_trans].[saved_search_rfq_likes]([rfq_id] ASC) WITH (FILLFACTOR = 90);


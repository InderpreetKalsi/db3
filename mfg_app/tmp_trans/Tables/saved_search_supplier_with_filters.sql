CREATE TABLE [tmp_trans].[saved_search_supplier_with_filters] (
    [contact_id]      INT NULL,
    [saved_search_id] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_saved_search_supplier_with_filters]
    ON [tmp_trans].[saved_search_supplier_with_filters]([contact_id] ASC, [saved_search_id] ASC) WITH (FILLFACTOR = 90);


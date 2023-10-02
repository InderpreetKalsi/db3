CREATE TABLE [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent] (
    [contact_id] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_saved_search_exclude_suppliers_to_whom_email_already_sent]
    ON [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent]([contact_id] ASC) WITH (FILLFACTOR = 90);


CREATE TABLE [dbo].[mp_saved_search_comp_processes] (
    [company_id]       INT NOT NULL,
    [part_category_id] INT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_mp_saved_search_comp_processes]
    ON [dbo].[mp_saved_search_comp_processes]([company_id] ASC, [part_category_id] ASC) WITH (FILLFACTOR = 90);


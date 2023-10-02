CREATE TABLE [dbo].[mp_saved_search_processes] (
    [saved_search_id]  INT NOT NULL,
    [part_category_id] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([saved_search_id] ASC, [part_category_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_mp_saved_search_processes]
    ON [dbo].[mp_saved_search_processes]([saved_search_id] ASC, [part_category_id] ASC) WITH (FILLFACTOR = 90);


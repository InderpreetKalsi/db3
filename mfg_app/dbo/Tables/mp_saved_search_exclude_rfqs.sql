CREATE TABLE [dbo].[mp_saved_search_exclude_rfqs] (
    [id]         INT IDENTITY (1, 1) NOT NULL,
    [contact_id] INT NULL,
    [rfq_id]     INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_saved_search_exclude_rfqs]
    ON [dbo].[mp_saved_search_exclude_rfqs]([contact_id] ASC) WITH (FILLFACTOR = 90);


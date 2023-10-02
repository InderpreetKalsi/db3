CREATE TABLE [tmp_trans].[saved_search_geocode] (
    [zipcode]  NVARCHAR (200) NULL,
    [distance] FLOAT (53)     NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_saved_search_geocode]
    ON [tmp_trans].[saved_search_geocode]([zipcode] ASC) WITH (FILLFACTOR = 90);


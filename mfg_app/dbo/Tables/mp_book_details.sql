CREATE TABLE [dbo].[mp_book_details] (
    [book_detail_id] INT      IDENTITY (1, 1) NOT NULL,
    [book_id]        INT      NOT NULL,
    [company_id]     INT      NOT NULL,
    [creation_date]  DATETIME NULL,
    CONSTRAINT [PK_mp_book_details] PRIMARY KEY CLUSTERED ([book_detail_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_book_details_mp_books] FOREIGN KEY ([book_id]) REFERENCES [dbo].[mp_books] ([book_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_book_details_company_id]
    ON [dbo].[mp_book_details]([company_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_book_details_book_id]
    ON [dbo].[mp_book_details]([book_id] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_book_details_book_id]
    ON [dbo].[mp_book_details]([book_id] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);


CREATE TABLE [dbo].[mp_books] (
    [book_id]        INT            IDENTITY (1, 1) NOT NULL,
    [bk_type]        SMALLINT       NOT NULL,
    [bk_name]        NVARCHAR (200) NOT NULL,
    [contact_id]     INT            NOT NULL,
    [parent_book_id] INT            NULL,
    [status_id]      INT            NOT NULL,
    CONSTRAINT [PK_mp_book] PRIMARY KEY CLUSTERED ([book_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_books_mp_mst_book_type] FOREIGN KEY ([bk_type]) REFERENCES [dbo].[mp_mst_book_type] ([book_type_id])
);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_books_bk_type_contact_id]
    ON [dbo].[mp_books]([bk_type] ASC, [contact_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_books_contact_id]
    ON [dbo].[mp_books]([contact_id] ASC) WITH (FILLFACTOR = 90);


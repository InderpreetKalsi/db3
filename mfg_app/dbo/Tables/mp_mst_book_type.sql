CREATE TABLE [dbo].[mp_mst_book_type] (
    [book_type_id] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [book_type]    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_mp_book_type] PRIMARY KEY CLUSTERED ([book_type_id] ASC) WITH (FILLFACTOR = 90)
);


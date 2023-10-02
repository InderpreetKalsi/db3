CREATE TABLE [dbo].[wp_terms] (
    [term_id]    BIGINT        NOT NULL,
    [name]       VARCHAR (200) NULL,
    [slug]       VARCHAR (200) NULL,
    [term_group] BIGINT        NULL,
    CONSTRAINT [pk_wp_terms_term_id] PRIMARY KEY NONCLUSTERED ([term_id] ASC)
);


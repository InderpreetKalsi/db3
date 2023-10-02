CREATE TABLE [dbo].[mp_accepted_nda] (
    [accepted_nda_id] INT            IDENTITY (1, 1) NOT NULL,
    [company_id]      INT            NULL,
    [contact_id]      INT            NULL,
    [creation_date]   DATETIME       NOT NULL,
    [nda_content]     NVARCHAR (MAX) NOT NULL,
    [status_id]       SMALLINT       NOT NULL,
    [NDA_LEVEL_ID]    SMALLINT       NULL,
    CONSTRAINT [PK_mp_accepted_nda] PRIMARY KEY CLUSTERED ([accepted_nda_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_accepted_nda_mp_contacts] FOREIGN KEY ([contact_id]) REFERENCES [dbo].[mp_contacts] ([contact_id])
);


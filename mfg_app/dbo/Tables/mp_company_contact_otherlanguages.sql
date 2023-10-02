CREATE TABLE [dbo].[mp_company_contact_otherlanguages] (
    [otherLanguage_id] INT      IDENTITY (1, 1) NOT NULL,
    [company_id]       INT      NOT NULL,
    [contact_id]       INT      NULL,
    [language_id]      SMALLINT NOT NULL,
    CONSTRAINT [PK_mp_company_contact_otherlanguages] PRIMARY KEY CLUSTERED ([otherLanguage_id] ASC) WITH (FILLFACTOR = 90)
);


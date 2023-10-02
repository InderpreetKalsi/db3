CREATE TABLE [dbo].[mp_mst_language] (
    [language_id]   SMALLINT      IDENTITY (1, 1) NOT NULL,
    [language_name] VARCHAR (100) NOT NULL,
    [language_abr]  VARCHAR (10)  NOT NULL,
    [charset]       VARCHAR (20)  DEFAULT ('Latin') NOT NULL,
    [locale_code]   VARCHAR (5)   NOT NULL,
    [hide]          BIT           DEFAULT ((0)) NOT NULL,
    [translated]    BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_mst_language] PRIMARY KEY CLUSTERED ([language_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Language definition', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_language';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ISO language and country code', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_language', @level2type = N'COLUMN', @level2name = N'locale_code';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'when 1, language is not available for the user on the app (except translated language list managed by TRANSLATED)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_language', @level2type = N'COLUMN', @level2name = N'hide';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'when 1, Language is translated in dictionnary and is available in translated languages list for the user. Even if HIDE = 1', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_language', @level2type = N'COLUMN', @level2name = N'translated';


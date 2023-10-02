CREATE TABLE [dbo].[mp_company_industries] (
    [company_industry_id] INT      IDENTITY (1, 1) NOT NULL,
    [company_id]          INT      NOT NULL,
    [industry_type_id]    SMALLINT NOT NULL,
    CONSTRAINT [PK_mp_company_industries] PRIMARY KEY CLUSTERED ([company_industry_id] ASC) WITH (FILLFACTOR = 90)
);


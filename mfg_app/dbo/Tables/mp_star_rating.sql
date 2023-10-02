CREATE TABLE [dbo].[mp_star_rating] (
    [star_rating_id]  INT             IDENTITY (1, 1) NOT NULL,
    [company_id]      INT             NULL,
    [no_of_stars]     DECIMAL (18, 2) NULL,
    [total_responses] INT             NULL,
    PRIMARY KEY CLUSTERED ([star_rating_id] ASC) WITH (FILLFACTOR = 90)
);


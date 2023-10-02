CREATE TABLE [dbo].[mp_nps_rating] (
    [nps_rating_id]   INT IDENTITY (1, 1) NOT NULL,
    [company_id]      INT NOT NULL,
    [nps_score]       INT NULL,
    [promoter_score]  INT NULL,
    [promoter_count]  INT NULL,
    [passive_score]   INT NULL,
    [passive_count]   INT NULL,
    [detractor_score] INT NULL,
    [detractor_count] INT NULL,
    [total_responses] INT NULL,
    CONSTRAINT [PK_mp_nps_rating] PRIMARY KEY CLUSTERED ([nps_rating_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_rating_responses] (
    [response_id]       INT             IDENTITY (1, 1) NOT NULL,
    [from_id]           INT             NULL,
    [to_id]             INT             NULL,
    [score]             NUMERIC (9, 2)  NULL,
    [comment]           NVARCHAR (MAX)  NULL,
    [created_date]      DATETIME        NULL,
    [parent_id]         INT             NULL,
    [ContactName]       NVARCHAR (2000) NULL,
    [ImageURL]          NVARCHAR (1000) NULL,
    [is_legacy_rating]  BIT             DEFAULT ((0)) NULL,
    [to_company_id]     INT             NULL,
    [old_score]         NUMERIC (10, 2) NULL,
    [rfq_id]            INT             NULL,
    [CommunityRatingID] INT             NULL,
    CONSTRAINT [pk_mp_rating_responses] PRIMARY KEY CLUSTERED ([response_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mpcommunityratings_mp_rating_responses] FOREIGN KEY ([CommunityRatingID]) REFERENCES [dbo].[mpCommunityRatings] ([Id])
);


CREATE TABLE [dbo].[mpCompanyRatingEmailPreferences] (
    [Id]        INT           IDENTITY (1, 1) NOT NULL,
    [CompanyId] INT           NULL,
    [Email]     VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_NonClustered_CompanyId]
    ON [dbo].[mpCompanyRatingEmailPreferences]([CompanyId] ASC) WITH (FILLFACTOR = 90);


CREATE TABLE [dbo].[mp_company_Industryfocus] (
    [company_Industryfocus_id] INT      IDENTITY (1, 1) NOT NULL,
    [company_id]               INT      NOT NULL,
    [IndustryBranches_id]      SMALLINT NOT NULL,
    CONSTRAINT [PK_mp_company_Industryfocus] PRIMARY KEY CLUSTERED ([company_Industryfocus_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_Industryfocus_mp_companies] FOREIGN KEY ([company_id]) REFERENCES [dbo].[mp_Companies] ([company_id]),
    CONSTRAINT [FK_mp_company_Industryfocus_mp_mst_IndustryBranches] FOREIGN KEY ([IndustryBranches_id]) REFERENCES [dbo].[mp_mst_IndustryBranches] ([IndustryBranches_id])
);


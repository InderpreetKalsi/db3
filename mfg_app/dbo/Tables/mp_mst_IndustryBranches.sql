CREATE TABLE [dbo].[mp_mst_IndustryBranches] (
    [IndustryBranches_id]        SMALLINT       IDENTITY (1, 1) NOT NULL,
    [IndustryBranches_name]      NVARCHAR (150) NULL,
    [IndustryBranches_name_EN]   NVARCHAR (300) NULL,
    [IndustryBranches_is_domain] BIT            NULL,
    [publish]                    BIT            NULL,
    [naics_code]                 NVARCHAR (256) NULL,
    [icb_code]                   NVARCHAR (256) NULL,
    CONSTRAINT [PK_mp_mst_IndustryBranches] PRIMARY KEY CLUSTERED ([IndustryBranches_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'when 0 Industry (for Supplier), when 1 Activity Domain (for Buyer)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_IndustryBranches', @level2type = N'COLUMN', @level2name = N'IndustryBranches_is_domain';


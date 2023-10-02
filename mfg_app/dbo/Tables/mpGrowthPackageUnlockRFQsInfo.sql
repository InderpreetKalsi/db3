CREATE TABLE [dbo].[mpGrowthPackageUnlockRFQsInfo] (
    [ID]         INT      IDENTITY (1, 1) NOT NULL,
    [CompanyId]  INT      NULL,
    [Rfq_Id]     INT      NULL,
    [UnlockBy]   INT      NULL,
    [UnlockDate] DATETIME DEFAULT (getdate()) NULL,
    [IsDeleted]  BIT      CONSTRAINT [DF_IsDeleted] DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


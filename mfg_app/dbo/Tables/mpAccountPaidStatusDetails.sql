CREATE TABLE [dbo].[mpAccountPaidStatusDetails] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [CompanyId]   INT           NOT NULL,
    [OldValue]    INT           NULL,
    [NewValue]    INT           NULL,
    [IsProcessed] BIT           NULL,
    [IsSynced]    BIT           NULL,
    [CreatedOn]   DATETIME      DEFAULT (getutcdate()) NULL,
    [SourceType]  VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


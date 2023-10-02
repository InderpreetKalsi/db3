CREATE TABLE [dbo].[bk_mpAccountPaidStatusDetails] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [CompanyId]   INT           NOT NULL,
    [OldValue]    INT           NULL,
    [NewValue]    INT           NULL,
    [IsProcessed] BIT           NULL,
    [IsSynced]    BIT           NULL,
    [CreatedOn]   DATETIME      NULL,
    [SourceType]  VARCHAR (100) NULL
);


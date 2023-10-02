CREATE TABLE [dbo].[mpUserGetStartedInfo] (
    [Id]               INT            IDENTITY (1, 1) NOT NULL,
    [ContactId]        INT            NULL,
    [StepId]           INT            NULL,
    [SubStepId]        INT            NULL,
    [IsPartFilesReady] BIT            NULL,
    [IsHelpNeeded]     BIT            NULL,
    [PartFiles]        NVARCHAR (MAX) NULL,
    [IsStandardNDA]    BIT            NULL,
    [IsSingleConfirm]  BIT            NULL,
    [CustomNDAFile]    NVARCHAR (MAX) NULL,
    [GetStartedDate]   DATETIME       DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


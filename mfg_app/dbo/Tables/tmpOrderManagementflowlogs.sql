CREATE TABLE [dbo].[tmpOrderManagementflowlogs] (
    [RfqId]    INT            NULL,
    [FlowName] VARCHAR (150)  NULL,
    [POJSON]   NVARCHAR (MAX) NULL,
    [FlowDate] DATETIME       CONSTRAINT [DF__tmpOrderM__FlowD__10484C7F] DEFAULT (getutcdate()) NULL,
    [Id]       INT            IDENTITY (1, 1) NOT NULL
);


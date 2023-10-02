CREATE TABLE [dbo].[mpOrderManagementStatusChangeLogs] (
    [Id]                INT           IDENTITY (100, 1) NOT NULL,
    [OrderManagementId] INT           NOT NULL,
    [OldStatus]         VARCHAR (100) NOT NULL,
    [NewStatus]         VARCHAR (100) NOT NULL,
    [CreatedOn]         DATETIME      CONSTRAINT [df_mpOrderManagementStatusChangeLogs_CreatedOn] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [pk_mpOrderManagementStatusChangeLogs_Id] PRIMARY KEY CLUSTERED ([Id] ASC, [OrderManagementId] ASC)
);


CREATE TABLE [dbo].[mpArchivedMessages] (
    [Id]              INT      IDENTITY (1, 1) NOT NULL,
    [ParentMessageId] INT      NULL,
    [MessageId]       INT      NULL,
    [ArchieveDate]    DATETIME DEFAULT (getutcdate()) NULL,
    [ArchievedBy]     INT      NULL,
    CONSTRAINT [Pk_mpArchivedMesssages_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


CREATE TABLE [dbo].[mpCompanyPublishProfileLogs] (
    [Id]                     INT      IDENTITY (101, 1) NOT NULL,
    [CompanyId]              INT      NOT NULL,
    [PublishProfileStatusId] INT      NOT NULL,
    [CreatedBy]              INT      NOT NULL,
    [CreatedOn]              DATETIME DEFAULT (getutcdate()) NOT NULL,
    [IsApproved]             BIT      NULL,
    [ApprovedBy]             INT      NULL,
    [ApprovedDate]           DATETIME NULL,
    CONSTRAINT [pk_mpCompanyPublishProfileLogs_CompanyId] PRIMARY KEY CLUSTERED ([CompanyId] ASC, [CreatedOn] ASC) WITH (FILLFACTOR = 90),
    FOREIGN KEY ([PublishProfileStatusId]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


GO
CREATE NONCLUSTERED INDEX [idx_mpCompanyPublishProfileLogs_CompanyId_PublishProfileStatusId]
    ON [dbo].[mpCompanyPublishProfileLogs]([CompanyId] ASC)
    INCLUDE([PublishProfileStatusId], [CreatedOn]) WITH (FILLFACTOR = 90);


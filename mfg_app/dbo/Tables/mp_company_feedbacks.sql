CREATE TABLE [dbo].[mp_company_feedbacks] (
    [Id]            INT      IDENTITY (101, 1) NOT NULL,
    [FromCompanyId] INT      NULL,
    [FromContactId] INT      NULL,
    [ToCompanyId]   INT      NULL,
    [FeedbackId]    INT      NULL,
    [FeedbackDate]  DATETIME DEFAULT (getutcdate()) NULL,
    CONSTRAINT [pk_mp_company_feedbacks_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [fk_mp_company_feedbacks_mp_system_parameters_FeedbackId_Id] FOREIGN KEY ([FeedbackId]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


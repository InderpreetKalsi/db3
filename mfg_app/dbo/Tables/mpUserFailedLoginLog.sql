CREATE TABLE [dbo].[mpUserFailedLoginLog] (
    [Id]           INT           IDENTITY (1, 1) NOT NULL,
    [Email]        VARCHAR (512) NULL,
    [ErrorMessage] VARCHAR (MAX) NULL,
    [LoginTime]    DATETIME      DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mpUserFailedLoginLog_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


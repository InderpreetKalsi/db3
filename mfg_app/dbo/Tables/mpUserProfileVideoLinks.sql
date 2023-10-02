CREATE TABLE [dbo].[mpUserProfileVideoLinks] (
    [Id]                   INT             IDENTITY (1, 1) NOT NULL,
    [CompanyId]            INT             NULL,
    [ContactId]            INT             NULL,
    [Title]                VARCHAR (250)   NULL,
    [VideoLink]            NVARCHAR (4000) NULL,
    [Description]          VARCHAR (500)   NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF__mpUserPro__IsDel__630072F2] DEFAULT ((0)) NULL,
    [IsLinkVisionAccepted] BIT             NULL,
    [CreatedOn]            DATETIME        CONSTRAINT [DF__mpUserPro__Creat__63F4972B] DEFAULT (getutcdate()) NULL,
    [ModifiedOn]           DATETIME        NULL,
    [ModifiedBy]           INT             NULL,
    [DeletedOn]            DATETIME        NULL,
    [DeletedBy]            INT             NULL,
    CONSTRAINT [PK__mpUserPr__3214EC0768C00308] PRIMARY KEY CLUSTERED ([Id] ASC)
);


CREATE TABLE [dbo].[mpBuyerIndustryModalAnswers] (
    [Id]        INT            IDENTITY (101, 1) NOT NULL,
    [BuyeId]    INT            NOT NULL,
    [CompanyId] INT            NOT NULL,
    [Questions] VARCHAR (500)  NOT NULL,
    [Answers]   VARCHAR (4000) NULL,
    [CreatedOn] DATETIME       DEFAULT (getutcdate()) NULL,
    CONSTRAINT [pk_mpBuyerIndustryModalAnswers_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mpBlockedDomainList] (
    [Id]         INT           IDENTITY (1, 1) NOT NULL,
    [DomainName] VARCHAR (100) NOT NULL,
    [IsBlocked]  BIT           DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


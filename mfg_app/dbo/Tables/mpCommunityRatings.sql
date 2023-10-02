CREATE TABLE [dbo].[mpCommunityRatings] (
    [Id]                  INT            IDENTITY (1, 1) NOT NULL,
    [IpAddress]           VARCHAR (100)  NULL,
    [SenderCompany]       VARCHAR (200)  NULL,
    [SenderEmail]         VARCHAR (100)  NULL,
    [FirstName]           VARCHAR (100)  NULL,
    [LastName]            VARCHAR (100)  NULL,
    [IsBuyer]             BIT            DEFAULT ((1)) NOT NULL,
    [ReceiverCompany]     VARCHAR (200)  NULL,
    [ReceiverEmail]       VARCHAR (100)  NULL,
    [Rating]              INT            NULL,
    [Comment]             NVARCHAR (MAX) NULL,
    [RatingDate]          DATETIME       NULL,
    [IsApproved]          BIT            NULL,
    [ApprovedDeclineBy]   INT            NULL,
    [ApprovedDeclineDate] DATETIME       NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


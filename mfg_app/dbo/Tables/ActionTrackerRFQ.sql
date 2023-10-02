CREATE TABLE [dbo].[ActionTrackerRFQ] (
    [Id]             INT            IDENTITY (1, 1) NOT NULL,
    [RfqId]          INT            NOT NULL,
    [ParentRfqId]    INT            NULL,
    [RfqName]        VARCHAR (200)  NULL,
    [RfqThumbnails]  VARCHAR (1000) NULL,
    [Rating]         INT            NULL,
    [BuyerId]        INT            NULL,
    [Buyer]          VARCHAR (250)  NULL,
    [BuyerEmail]     VARCHAR (250)  NULL,
    [BuyerCompany]   VARCHAR (200)  NULL,
    [RfqCloseDate]   DATETIME       NULL,
    [RfqReleaseDate] DATETIME       NULL,
    [Reviewed]       INT            DEFAULT ((0)) NULL,
    [Liked]          INT            DEFAULT ((0)) NULL,
    [Marked]         INT            DEFAULT ((0)) NULL,
    [Quotes]         INT            DEFAULT ((0)) NULL,
    [Location]       VARCHAR (200)  NULL,
    [Status]         VARCHAR (200)  NULL,
    CONSTRAINT [PK_ActionTrackerRFQ_RfqId] PRIMARY KEY CLUSTERED ([RfqId] ASC, [Id] ASC) WITH (FILLFACTOR = 90)
);


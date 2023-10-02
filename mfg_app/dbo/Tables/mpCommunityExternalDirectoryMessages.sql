CREATE TABLE [dbo].[mpCommunityExternalDirectoryMessages] (
    [Id]                  INT           IDENTITY (101, 1) NOT NULL,
    [BuyerEmail]          VARCHAR (150) NULL,
    [BuyerFirstName]      VARCHAR (150) NULL,
    [BuyerLastName]       VARCHAR (150) NULL,
    [BuyerCompanyName]    VARCHAR (250) NULL,
    [BuyerPhone]          VARCHAR (50)  NULL,
    [MessageFileId]       INT           NULL,
    [EmailSubject]        VARCHAR (250) NULL,
    [EmailBody]           VARCHAR (MAX) NULL,
    [IpAddress]           VARCHAR (150) NULL,
    [SupplierFirstName]   VARCHAR (150) NULL,
    [SupplierLastName]    VARCHAR (150) NULL,
    [SupplierEmail]       VARCHAR (150) NULL,
    [SupplierCompanyName] VARCHAR (250) NULL,
    [IsInSolr]            BIT           DEFAULT ((0)) NULL,
    [IsInMfg]             BIT           DEFAULT ((0)) NULL,
    [IsClaimed]           BIT           DEFAULT ((0)) NULL,
    [EmailMessageDate]    DATETIME      DEFAULT (getutcdate()) NULL,
    [IsNdaRequired]       BIT           NULL,
    CONSTRAINT [pk_mpCommunityExternalDirectoryMessages_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [fk_mpCommunityExternalDirectoryMessages_mp_special_files_MessageFileId_FILE_ID] FOREIGN KEY ([MessageFileId]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


GO
ALTER TABLE [dbo].[mpCommunityExternalDirectoryMessages] NOCHECK CONSTRAINT [fk_mpCommunityExternalDirectoryMessages_mp_special_files_MessageFileId_FILE_ID];


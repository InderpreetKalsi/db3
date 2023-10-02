CREATE TABLE [dbo].[mpCommunityLeadStream] (
    [Id]                INT           IDENTITY (1, 1) NOT NULL,
    [IpAddress]         VARCHAR (150) NULL,
    [BuyerEmail]        VARCHAR (200) NULL,
    [BuyerFirstName]    VARCHAR (200) NULL,
    [BuyerLastName]     VARCHAR (200) NULL,
    [LeadSourceId]      INT           NULL,
    [SupplierEmail]     VARCHAR (200) NULL,
    [SupplierFirstName] VARCHAR (200) NULL,
    [SupplierLastName]  VARCHAR (200) NULL,
    [LeadDate]          DATETIME      DEFAULT (getutcdate()) NULL,
    [IsClaimed]         BIT           DEFAULT ((0)) NULL,
    [BuyerPhoneNo]      VARCHAR (250) NULL,
    [IsFromGatedForm]   BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [pk_mpCommunityLeadStream_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [fk_mpCommunityLeadStream_mp_lead_mp_mst_lead_source_LeadSourceId_lead_source_id] FOREIGN KEY ([LeadSourceId]) REFERENCES [dbo].[mp_mst_lead_source] ([lead_source_id])
);


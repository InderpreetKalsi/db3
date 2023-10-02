CREATE TABLE [dbo].[mp_magic_leads] (
    [magic_lead_id]       INT      IDENTITY (1, 1) NOT NULL,
    [supplier_company_id] INT      NULL,
    [buyer_company_id]    INT      NULL,
    [lead_date]           DATETIME DEFAULT (getutcdate()) NULL,
    [is_expired]          BIT      DEFAULT ((0)) NULL,
    [account_type]        SMALLINT NULL,
    [is_viewed]           BIT      NULL,
    PRIMARY KEY CLUSTERED ([magic_lead_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_spotlight_supplier] (
    [spotlight_id]         INT      IDENTITY (1, 1) NOT NULL,
    [part_category_id]     INT      NULL,
    [expiry_date]          DATETIME NULL,
    [is_spotlight_turn_on] BIT      DEFAULT ((0)) NULL,
    [turnon_date]          DATETIME DEFAULT (getutcdate()) NULL,
    [RankPosition]         INT      NULL,
    [CompanyId]            INT      NULL,
    [location_id]          INT      NULL,
    CONSTRAINT [PK_mp_Spotlight_Supplier_spotlight_id] PRIMARY KEY CLUSTERED ([spotlight_id] ASC)
);


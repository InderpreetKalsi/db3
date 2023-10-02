CREATE TABLE [dbo].[tmp_SQLJob_Quote_RFQItemsData] (
    [rfq_id]               INT             NOT NULL,
    [rfq_name]             NVARCHAR (100)  NULL,
    [company_id]           INT             NOT NULL,
    [CompanyName]          NVARCHAR (150)  NULL,
    [part_number]          NVARCHAR (450)  NULL,
    [part_name]            NVARCHAR (450)  NULL,
    [part_id]              BIGINT          NOT NULL,
    [rfq_quote_items_id]   INT             NOT NULL,
    [rfq_part_quantity_id] INT             NULL,
    [awarded_qty]          NUMERIC (18, 2) NULL,
    [total_after_discount] NUMERIC (38, 4) NULL,
    [per_unit_price]       NUMERIC (18, 2) NOT NULL,
    [part_description]     NVARCHAR (MAX)  NULL
);


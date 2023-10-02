CREATE TABLE [dbo].[tmp_ssis_Legacy_RatingData] (
    [SUPPLIER_ID]            INT             NULL,
    [SUPPLIER_COMPANY]       NVARCHAR (4000) NULL,
    [BUYER_ID]               INT             NULL,
    [BUYER_NAME]             NVARCHAR (4000) NULL,
    [RATING_AVERAGE_OUTOF10] NUMERIC (9, 2)  NULL,
    [RATING_AVERAGE]         NUMERIC (9, 2)  NULL,
    [NPS_STRUCTURE]          NVARCHAR (100)  NULL,
    [AUTHOR_COMMENT]         NVARCHAR (MAX)  NULL,
    [RATING_DATE]            DATETIME        NULL
);


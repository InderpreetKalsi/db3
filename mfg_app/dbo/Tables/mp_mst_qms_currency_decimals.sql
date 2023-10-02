CREATE TABLE [dbo].[mp_mst_qms_currency_decimals] (
    [qms_currency_decimal_id] INT           IDENTITY (101, 1) NOT NULL,
    [qms_currency_decimal]    VARCHAR (500) NULL,
    [sort_order]              SMALLINT      NULL,
    [is_active]               BIT           DEFAULT ((1)) NULL,
    [created_on]              DATETIME      DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([qms_currency_decimal_id] ASC) WITH (FILLFACTOR = 90)
);


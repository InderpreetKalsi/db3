CREATE TABLE [dbo].[mp_mst_currency] (
    [currency_id]        INT          IDENTITY (1, 1) NOT NULL,
    [currency_name]      VARCHAR (50) NULL,
    [currency_code]      VARCHAR (50) NULL,
    [currency_value]     FLOAT (53)   NULL,
    [to_display]         BIT          NULL,
    [CURRENCY_SYMBOL]    NVARCHAR (5) NULL,
    [LEFT_SYMBOL]        BIT          NULL,
    [THOUSAND_SEPARATOR] NCHAR (1)    NULL,
    [DECIMAL_SEPARATOR]  NCHAR (1)    NULL,
    [ISO_NUM_CODE]       CHAR (3)     NULL,
    CONSTRAINT [PK_mp_mst_currency] PRIMARY KEY CLUSTERED ([currency_id] ASC) WITH (FILLFACTOR = 90)
);


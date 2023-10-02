CREATE TABLE [dbo].[mp_rfq_shopiq_metrics] (
    [rfq_shopiq_id]        INT             IDENTITY (1, 1) NOT NULL,
    [rfq_id]               INT             NOT NULL,
    [rfq_part_id]          INT             NOT NULL,
    [rfq_part_quantity_id] INT             NULL,
    [quantity]             VARCHAR (75)    NULL,
    [is_awarded]           BIT             DEFAULT ((0)) NULL,
    [avg_marketprice]      DECIMAL (15, 2) DEFAULT ((0.0)) NULL,
    [awarded_price]        DECIMAL (15, 4) DEFAULT ((0.0)) NULL,
    [award_date]           DATETIME        NULL,
    [metrics_date]         DATETIME        DEFAULT (getutcdate()) NULL,
    [part_name]            VARCHAR (500)   NULL,
    [process]              VARCHAR (200)   NULL,
    [material]             VARCHAR (200)   NULL,
    [LowPrice]             DECIMAL (15, 2) DEFAULT ((0)) NULL,
    [HighPrice]            DECIMAL (15, 2) DEFAULT ((0)) NULL,
    [IsAwardedToOtherQty]  BIT             NULL,
    CONSTRAINT [pk_mp_rfq_shopiq_metrics_rfq_shopiq_id_rfq_id_rfq_part_id] PRIMARY KEY CLUSTERED ([rfq_shopiq_id] ASC, [rfq_id] ASC, [rfq_part_id] ASC) WITH (FILLFACTOR = 90)
);


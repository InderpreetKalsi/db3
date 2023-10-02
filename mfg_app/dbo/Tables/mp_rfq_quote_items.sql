CREATE TABLE [dbo].[mp_rfq_quote_items] (
    [rfq_quote_items_id]             INT             IDENTITY (1, 1) NOT NULL,
    [rfq_quote_SupplierQuote_id]     INT             NOT NULL,
    [rfq_part_id]                    INT             NOT NULL,
    [per_unit_price]                 NUMERIC (18, 4) NOT NULL,
    [tooling_amount]                 NUMERIC (18, 4) NULL,
    [miscellaneous_amount]           NUMERIC (18, 4) NULL,
    [shipping_amount]                NUMERIC (18, 4) NULL,
    [rfq_part_quantity_id]           INT             NULL,
    [is_awrded]                      BIT             NULL,
    [awarded_qty]                    NUMERIC (18, 2) NULL,
    [awarded_date]                   DATETIME        NULL,
    [is_award_accepted]              BIT             NULL,
    [award_accepted_Or_decline_date] DATE            NULL,
    [est_lead_time_value]            DECIMAL (4, 1)  NULL,
    [est_lead_time_range]            VARCHAR (150)   NULL,
    [is_continue_awarding]           BIT             NULL,
    [status_id]                      INT             NULL,
    [unit]                           NUMERIC (18, 2) NULL,
    [unit_type_id]                   INT             NULL,
    [price]                          NUMERIC (18, 4) NULL,
    [ReshapePartStatus]              VARCHAR (25)    NULL,
    [AwardedRegionId]                INT             NULL,
    [AwardedCompanyId]               INT             NULL,
    [AwardedCompanyName]             NVARCHAR (300)  NULL,
    [AwardedWhyOfflineReason]        NVARCHAR (MAX)  NULL,
    [NotAwardedReason]               NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_mp_rfq_quote_items] PRIMARY KEY CLUSTERED ([rfq_quote_items_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_quote_items_mp_rfq_part_quantity] FOREIGN KEY ([rfq_part_quantity_id]) REFERENCES [dbo].[mp_rfq_part_quantity] ([rfq_part_quantity_id]),
    CONSTRAINT [FK_mp_rfq_quote_items_mp_rfq_parts] FOREIGN KEY ([rfq_part_id]) REFERENCES [dbo].[mp_rfq_parts] ([rfq_part_id]),
    CONSTRAINT [FK_mp_rfq_quote_items_mp_rfq_quote_SupplierQuote] FOREIGN KEY ([rfq_quote_SupplierQuote_id]) REFERENCES [dbo].[mp_rfq_quote_SupplierQuote] ([rfq_quote_SupplierQuote_id])
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_quote_items_is_awrded_rfq_quote_SupplierQuote_id]
    ON [dbo].[mp_rfq_quote_items]([is_awrded] ASC)
    INCLUDE([rfq_quote_SupplierQuote_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_rfq_quote_items]
    ON [dbo].[mp_rfq_quote_items]([rfq_quote_SupplierQuote_id] ASC)
    INCLUDE([rfq_part_id], [per_unit_price], [tooling_amount], [miscellaneous_amount], [shipping_amount], [rfq_part_quantity_id], [awarded_qty]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_quote_items_is_awrded_status_id]
    ON [dbo].[mp_rfq_quote_items]([is_awrded] ASC, [status_id] ASC)
    INCLUDE([rfq_quote_SupplierQuote_id], [awarded_date]) WITH (FILLFACTOR = 90);


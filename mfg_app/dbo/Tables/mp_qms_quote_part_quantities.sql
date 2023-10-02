CREATE TABLE [dbo].[mp_qms_quote_part_quantities] (
    [qms_quote_part_qty_id] INT          IDENTITY (1, 1) NOT NULL,
    [qms_quote_part_id]     INT          NOT NULL,
    [part_qty]              NUMERIC (18) NULL,
    [part_qty_unit_id]      INT          NULL,
    [qty_level]             SMALLINT     NULL,
    [is_deleted]            BIT          CONSTRAINT [DF__mp_qms_qu__is_de__4F0C92CB] DEFAULT ((0)) NOT NULL,
    [modified_date]         DATETIME     NULL,
    CONSTRAINT [pk_mp_qms_quote_part_quantities_qms_quote_part_qty_id] PRIMARY KEY CLUSTERED ([qms_quote_part_qty_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK__mp_qms_qu__qms_q__4A47DDAE] FOREIGN KEY ([qms_quote_part_id]) REFERENCES [dbo].[mp_qms_quote_parts] ([qms_quote_part_id])
);


GO
ALTER TABLE [dbo].[mp_qms_quote_part_quantities] NOCHECK CONSTRAINT [FK__mp_qms_qu__qms_q__4A47DDAE];


CREATE TABLE [dbo].[mp_qms_quote_part_special_fees] (
    [quote_part_special_fee_id] INT             IDENTITY (1, 1) NOT NULL,
    [qms_quote_part_id]         INT             NOT NULL,
    [fee_type_id]               INT             NOT NULL,
    [value]                     NUMERIC (18, 4) NULL,
    [is_deleted]                BIT             DEFAULT ((0)) NULL,
    CONSTRAINT [pk_mp_qms_quote_part_special_fees] PRIMARY KEY CLUSTERED ([quote_part_special_fee_id] ASC, [qms_quote_part_id] ASC, [fee_type_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_qms_quote_part_special_fees_mp_qms_quote_parts] FOREIGN KEY ([qms_quote_part_id]) REFERENCES [dbo].[mp_qms_quote_parts] ([qms_quote_part_id]) ON DELETE CASCADE ON UPDATE CASCADE
);


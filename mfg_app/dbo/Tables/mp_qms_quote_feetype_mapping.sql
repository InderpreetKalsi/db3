CREATE TABLE [dbo].[mp_qms_quote_feetype_mapping] (
    [qms_quote_feetype_mapping_id] INT IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]                 INT NOT NULL,
    [qms_quote_part_id]            INT NULL,
    [qms_dynamic_fee_type_id]      INT NULL,
    PRIMARY KEY CLUSTERED ([qms_quote_feetype_mapping_id] ASC, [qms_quote_id] ASC) WITH (FILLFACTOR = 90)
);


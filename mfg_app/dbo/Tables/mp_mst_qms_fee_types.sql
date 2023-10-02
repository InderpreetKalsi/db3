CREATE TABLE [dbo].[mp_mst_qms_fee_types] (
    [qms_fee_type_id] INT           IDENTITY (1, 1) NOT NULL,
    [fee_type]        VARCHAR (150) NOT NULL,
    [is_active]       BIT           CONSTRAINT [DF_mp_mst_qms_fee_types_is_active] DEFAULT ((1)) NOT NULL,
    [sort_order]      SMALLINT      NULL,
    CONSTRAINT [PK_mp_mst_qms_fee_types] PRIMARY KEY CLUSTERED ([qms_fee_type_id] ASC) WITH (FILLFACTOR = 90)
);


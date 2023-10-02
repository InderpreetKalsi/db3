CREATE TABLE [tmp_trans].[revision_data_history_3] (
    [data_history_id]            BIGINT          NULL,
    [userid]                     INT             NULL,
    [creation_date]              DATETIME        NULL,
    [tablename]                  NVARCHAR (50)   NULL,
    [rfq_id]                     INT             NULL,
    [rfq_part_id]                INT             NULL,
    [rfq_part_qty_id]            INT             NULL,
    [rfq_special_certificate_id] INT             NULL,
    [rfq_preference_id]          INT             NULL,
    [Id]                         INT             NULL,
    [RFQAttributes]              NVARCHAR (2500) NULL,
    [OldValues]                  NVARCHAR (2500) NULL,
    [NewValues]                  NVARCHAR (2500) NULL,
    [Field]                      NVARCHAR (2500) NULL,
    [oldvalue]                   NVARCHAR (2500) NULL,
    [newvalue]                   NVARCHAR (2500) NULL
);


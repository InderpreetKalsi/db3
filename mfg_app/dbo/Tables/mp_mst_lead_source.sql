CREATE TABLE [dbo].[mp_mst_lead_source] (
    [lead_source_id]   INT           IDENTITY (1, 1) NOT NULL,
    [lead_source]      VARCHAR (150) NULL,
    [lead_source_desc] VARCHAR (250) NULL,
    [is_active]        BIT           DEFAULT ((1)) NULL,
    [is_internal]      BIT           NULL,
    PRIMARY KEY CLUSTERED ([lead_source_id] ASC) WITH (FILLFACTOR = 90)
);


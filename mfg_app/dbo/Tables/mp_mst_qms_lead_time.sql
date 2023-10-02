CREATE TABLE [dbo].[mp_mst_qms_lead_time] (
    [qms_lead_time_id] INT           IDENTITY (1, 1) NOT NULL,
    [lead_time]        VARCHAR (150) NOT NULL,
    [is_active]        BIT           CONSTRAINT [DF_mp_mst_qms_lead_time_is_active] DEFAULT ((1)) NOT NULL,
    [sort_order]       SMALLINT      NULL,
    CONSTRAINT [PK_mp_mst_qms_lead_time] PRIMARY KEY CLUSTERED ([qms_lead_time_id] ASC) WITH (FILLFACTOR = 90)
);


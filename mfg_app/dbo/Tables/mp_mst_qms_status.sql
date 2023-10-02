CREATE TABLE [dbo].[mp_mst_qms_status] (
    [qms_status_id] INT           IDENTITY (1, 1) NOT NULL,
    [sys_key]       VARCHAR (50)  NULL,
    [status]        VARCHAR (50)  NULL,
    [description]   VARCHAR (250) NULL,
    [position]      SMALLINT      NULL,
    [is_active]     BIT           DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([qms_status_id] ASC) WITH (FILLFACTOR = 90)
);


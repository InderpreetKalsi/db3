CREATE TABLE [dbo].[mp_data_history] (
    [data_history_id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [field]           NVARCHAR (400) NULL,
    [oldvalue]        NVARCHAR (MAX) NULL,
    [newvalue]        NVARCHAR (MAX) NULL,
    [creation_date]   DATETIME       NULL,
    [userid]          INT            NULL,
    [tablename]       NVARCHAR (50)  NULL,
    [is_processed]    BIT            DEFAULT ((0)) NOT NULL,
    [processed_date]  DATETIME       NULL,
    CONSTRAINT [PK_mp_data_history] PRIMARY KEY CLUSTERED ([data_history_id] ASC) WITH (FILLFACTOR = 90)
);


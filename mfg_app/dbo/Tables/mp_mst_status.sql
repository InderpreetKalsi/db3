CREATE TABLE [dbo].[mp_mst_status] (
    [status_id]   SMALLINT      IDENTITY (1, 1) NOT NULL,
    [status_key]  VARCHAR (50)  NOT NULL,
    [description] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_mp_mst_status] PRIMARY KEY CLUSTERED ([status_id] ASC) WITH (FILLFACTOR = 90)
);


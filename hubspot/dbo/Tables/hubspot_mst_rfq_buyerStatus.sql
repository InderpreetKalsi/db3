CREATE TABLE [dbo].[hubspot_mst_rfq_buyerStatus] (
    [rfq_buyerstatus_id]     SMALLINT      IDENTITY (1, 1) NOT NULL,
    [rfq_buyerstatus_li_key] VARCHAR (200) NOT NULL,
    [description]            VARCHAR (50)  NOT NULL,
    [position]               SMALLINT      NOT NULL,
    CONSTRAINT [PK_hubspot_mst_rfq_buyerStatus] PRIMARY KEY CLUSTERED ([rfq_buyerstatus_id] ASC) WITH (FILLFACTOR = 80)
);


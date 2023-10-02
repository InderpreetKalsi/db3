CREATE TABLE [dbo].[mp_lead] (
    [lead_id]           INT            IDENTITY (1, 1) NOT NULL,
    [company_id]        INT            NOT NULL,
    [lead_source_id]    INT            NULL,
    [lead_from_contact] INT            NULL,
    [ip_address]        VARCHAR (100)  NULL,
    [lead_date]         DATETIME       NULL,
    [status_id]         SMALLINT       NULL,
    [ModifiedBy]        INT            NULL,
    [ModifiedOn]        DATETIME       NULL,
    [value]             VARCHAR (1000) NULL,
    PRIMARY KEY CLUSTERED ([lead_id] ASC) WITH (FILLFACTOR = 90),
    FOREIGN KEY ([lead_source_id]) REFERENCES [dbo].[mp_mst_lead_source] ([lead_source_id])
);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_lead_company_id_lead_source_id]
    ON [dbo].[mp_lead]([company_id] ASC, [lead_source_id] ASC)
    INCLUDE([lead_from_contact], [ip_address], [lead_date]) WITH (FILLFACTOR = 90);


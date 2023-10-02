CREATE TABLE [dbo].[mp_rfq_quote_suplierStatuses] (
    [rfq_quot_suplierStatuses_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                      INT      NULL,
    [contact_id]                  INT      NULL,
    [rfq_userStatus_id]           SMALLINT NULL,
    [creation_date]               DATETIME NULL,
    [is_legacy_data]              BIT      NULL,
    [modification_date]           DATETIME NULL,
    [IsTrash]                     BIT      DEFAULT ((0)) NULL,
    [TrashDate]                   DATETIME DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_rfq_quote_suplierStatuses] PRIMARY KEY CLUSTERED ([rfq_quot_suplierStatuses_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_quote_suplierStatuses_mp_mst_rfq_UserStatus] FOREIGN KEY ([rfq_userStatus_id]) REFERENCES [dbo].[mp_mst_rfq_UserStatus] ([rfq_userStatus_id]),
    CONSTRAINT [FK_mp_rfq_quote_suplierStatuses_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
CREATE NONCLUSTERED INDEX [nc_mp_rfq_quote_suplierStatuses_rfq_id]
    ON [dbo].[mp_rfq_quote_suplierStatuses]([rfq_id] ASC)
    INCLUDE([contact_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_quote_suplierStatuses_01]
    ON [dbo].[mp_rfq_quote_suplierStatuses]([contact_id] ASC, [rfq_userStatus_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_rfq_quote_suplierstatuses_contact_id]
    ON [dbo].[mp_rfq_quote_suplierStatuses]([contact_id] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


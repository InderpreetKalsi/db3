CREATE TABLE [dbo].[mp_rfq_release_history] (
    [rfq_release_history_id] INT      IDENTITY (1, 1) NOT NULL,
    [rfq_id]                 INT      NOT NULL,
    [status_id]              SMALLINT NOT NULL,
    [status_date]            DATETIME NULL,
    [last_status]            BIT      NOT NULL,
    CONSTRAINT [PK_SP_RFX_BUYERSTATUSHISTORY] PRIMARY KEY CLUSTERED ([rfq_release_history_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_release_history_mp_BUYERSTATUS] FOREIGN KEY ([status_id]) REFERENCES [dbo].[mp_mst_rfq_buyerStatus] ([rfq_buyerstatus_id])
);


GO
CREATE NONCLUSTERED INDEX [IX__mp_rfq_release_history_RFQ_ID]
    ON [dbo].[mp_rfq_release_history]([rfq_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_release_history_RFQID_status_id]
    ON [dbo].[mp_rfq_release_history]([rfq_id] ASC, [status_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_release_history_incl_RFQID_status_date]
    ON [dbo].[mp_rfq_release_history]([status_id] ASC)
    INCLUDE([rfq_id], [status_date]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_rfq_release_history_status_date]
    ON [dbo].[mp_rfq_release_history]([status_id] ASC, [last_status] ASC, [status_date] ASC)
    INCLUDE([rfq_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Store the history of the field SP_RFQ. SYSTEM_RFX_BUYERSTATUS_ID.  Good table for DBA to use to keep track of changes.  This table is also the only way to keep track of the exact date that an RFQ went live.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_release_history';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'RFx Buyer Status History Identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_release_history', @level2type = N'COLUMN', @level2name = N'rfq_release_history_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_release_history', @level2type = N'COLUMN', @level2name = N'rfq_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 when last status for the RFQ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_release_history', @level2type = N'COLUMN', @level2name = N'last_status';


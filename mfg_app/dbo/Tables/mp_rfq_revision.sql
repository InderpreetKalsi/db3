CREATE TABLE [dbo].[mp_rfq_revision] (
    [rfq_revision_id]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [rfq_id]               INT            NOT NULL,
    [field]                NVARCHAR (400) NOT NULL,
    [oldvalue]             NVARCHAR (MAX) NOT NULL,
    [newvalue]             NVARCHAR (MAX) NOT NULL,
    [creation_date]        DATETIME       NOT NULL,
    [rfq_version_id]       BIGINT         NOT NULL,
    [is_Cleaned_data]      BIT            DEFAULT ((0)) NOT NULL,
    [need_Level2_Cleaning] BIT            DEFAULT ((1)) NULL,
    CONSTRAINT [PK_mp_rfq_revision] PRIMARY KEY CLUSTERED ([rfq_revision_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_revision_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id]),
    CONSTRAINT [FK_mp_rfq_revision_mp_rfq_versions] FOREIGN KEY ([rfq_version_id]) REFERENCES [dbo].[mp_rfq_versions] ([rfq_version_id])
);


GO
ALTER TABLE [dbo].[mp_rfq_revision] NOCHECK CONSTRAINT [FK_mp_rfq_revision_mp_rfq_versions];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table will be used for holding the RFQ historical data changes', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_revision', @level2type = N'COLUMN', @level2name = N'rfq_revision_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Holds the Rfq id ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_revision', @level2type = N'COLUMN', @level2name = N'rfq_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Holds the Field which has changes', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_revision', @level2type = N'COLUMN', @level2name = N'field';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Old value for the field', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_revision', @level2type = N'COLUMN', @level2name = N'oldvalue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'new value for the field', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_revision', @level2type = N'COLUMN', @level2name = N'newvalue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_rfq_versions table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_revision', @level2type = N'COLUMN', @level2name = N'rfq_version_id';


CREATE TABLE [dbo].[mp_company_certificates] (
    [company_certificates_id]    INT            IDENTITY (1, 1) NOT NULL,
    [company_id]                 INT            NOT NULL,
    [certificates_id]            INT            NOT NULL,
    [start_date]                 SMALLDATETIME  NULL,
    [end_date]                   SMALLDATETIME  NULL,
    [file_id]                    INT            NULL,
    [record_origin_id]           SMALLINT       NOT NULL,
    [status_id]                  INT            NOT NULL,
    [creation_date]              DATETIME       NOT NULL,
    [creation_contact_id]        INT            NULL,
    [modified_date]              DATETIME       NULL,
    [modified_contact_id]        INT            NULL,
    [renew_date]                 DATETIME       NULL,
    [renew_reminder_date]        DATETIME       NULL,
    [ref_number]                 NVARCHAR (510) NULL,
    [reviewed]                   BIT            NOT NULL,
    [reviewed_date]              DATETIME       NULL,
    [reviewed_contact_id]        INT            NULL,
    [renew_reminder_sent_date]   DATETIME       NULL,
    [auditor]                    NVARCHAR (510) NULL,
    [status_buyer_flag]          INT            NULL,
    [status_buyer_modified_by]   INT            NULL,
    [modified_status_buyer_date] DATETIME       NULL,
    CONSTRAINT [PK_mp_company_certificates] PRIMARY KEY CLUSTERED ([company_certificates_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_certificates_mp_certificates] FOREIGN KEY ([certificates_id]) REFERENCES [dbo].[mp_certificates] ([certificate_id]) NOT FOR REPLICATION,
    CONSTRAINT [FK_mp_company_certificates_mp_companies] FOREIGN KEY ([company_id]) REFERENCES [dbo].[mp_Companies] ([company_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_company_certificates_certificates_id]
    ON [dbo].[mp_company_certificates]([certificates_id] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Record Origin. 0 mfgjsp, 1 mfg, 2 Thales, 3 Sourcingparts', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'record_origin_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Status of a certificate, default is VALID. See SP_STATUS, values will be 2-STATUS_VALID, 4-STATUS_HIDE, 12-STATUS_ARCHIVED', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'status_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Optional, renewal date for that certificate', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'renew_date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Reminder date for renew', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'renew_reminder_date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ref number of certificate', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'ref_number';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Flag certificate reviewed by buyer (1 = reviewed)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'reviewed';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'When buyer had reviewed the certificate', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'reviewed_date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Who has reviewed the certificate.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'reviewed_contact_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Field is null by default, and will be set when the email will be effectively sent. This is a new field added as of 1/1//2017', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'renew_reminder_sent_date';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Auditor name that have establish that certificate', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'auditor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'int, nullable, default null. Linked to SP_STATUS : that status is internal for buyer, he can set is as approved or rejected for its own reason, but it do not alter the current status flag of the certificate.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'status_buyer_flag';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'numeric, nullable, default null, Buyer that have changed the internal status, linked to SP_CONT table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'status_buyer_modified_by';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Datetime, nullable, default null. datetime of the change done by buyer.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_certificates', @level2type = N'COLUMN', @level2name = N'modified_status_buyer_date';


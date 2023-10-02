CREATE TABLE [dbo].[mp_contacts_preferences] (
    [preference_id]                 INT            IDENTITY (1, 1) NOT NULL,
    [contact_id]                    INT            NOT NULL,
    [NDA_Level]                     SMALLINT       NULL,
    [payment_term_id]               VARCHAR (150)  NULL,
    [company_id]                    INT            NULL,
    [creation_date]                 DATETIME       NULL,
    [nda_content]                   NVARCHAR (MAX) NULL,
    [status_id]                     SMALLINT       NULL,
    [NDA_File_id]                   INT            NULL,
    [isbuyer_payshipping]           BIT            NULL,
    [pref_rfq_communication_method] INT            DEFAULT ((117)) NOT NULL,
    CONSTRAINT [PK_mp_cont_preferences] PRIMARY KEY CLUSTERED ([preference_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_contacts_preferences_mp_contacts] FOREIGN KEY ([contact_id]) REFERENCES [dbo].[mp_contacts] ([contact_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'contains contact preferrences like, selected NDA level Required to View RFQ Attachments, Payment terms linked to mp_paymentterm table and Preferred Manufacturing Location linked to mp_industries', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_preferences';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Unique identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_preferences', @level2type = N'COLUMN', @level2name = N'preference_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'contact id linked to mp_contacts table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_preferences', @level2type = N'COLUMN', @level2name = N'contact_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'maintain NDA level Required to View RFQ Attachments, linked to  mp_system_parameters', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_preferences', @level2type = N'COLUMN', @level2name = N'NDA_Level';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Defines buyers payment terms Payment terms linked to mp_paymentterm table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_preferences', @level2type = N'COLUMN', @level2name = N'payment_term_id';


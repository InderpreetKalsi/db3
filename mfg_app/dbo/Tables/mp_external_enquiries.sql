CREATE TABLE [dbo].[mp_external_enquiries] (
    [external_enquiries] BIGINT         IDENTITY (1, 1) NOT NULL,
    [first_name]         NVARCHAR (50)  NULL,
    [last_name]          NVARCHAR (50)  NULL,
    [company_name]       NVARCHAR (150) NOT NULL,
    [email]              NVARCHAR (200) NOT NULL,
    [Phone]              NVARCHAR (25)  NOT NULL,
    [company_id]         INT            NOT NULL,
    [contact_id]         INT            NOT NULL,
    [contact_email_id]   NVARCHAR (200) NOT NULL,
    [message_subject]    NVARCHAR (200) NOT NULL,
    [message_body]       NVARCHAR (MAX) NOT NULL,
    [message_date]       DATETIME       NOT NULL,
    CONSTRAINT [PK_mp_external_enquiries] PRIMARY KEY CLUSTERED ([external_enquiries] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identity column', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'external_enquiries';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'First name of the sender', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'first_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'last name of the sender', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'last_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'company name of the sender', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'company_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'email of the sender', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'email';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'contact number of the sender', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'Phone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_companies and holds the supplier company id from mp_companies table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'company_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'subject of the message', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'message_subject';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'message body', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'message_body';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'date on which message sent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_external_enquiries', @level2type = N'COLUMN', @level2name = N'message_date';


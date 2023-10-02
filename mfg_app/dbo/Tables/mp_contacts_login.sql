CREATE TABLE [dbo].[mp_contacts_login] (
    [contact_id]    INT            IDENTITY (1, 1) NOT NULL,
    [pwd]           NVARCHAR (125) NULL,
    [is_active]     BIT            DEFAULT ((1)) NULL,
    [last_login_on] DATETIME       NULL,
    [email]         NVARCHAR (120) NOT NULL,
    [role_id]       SMALLINT       DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([contact_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User login information in a company', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_login';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked contact_id in mp_contacts table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_login', @level2type = N'COLUMN', @level2name = N'contact_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Active flag for the contact, default will be 0-Inactive.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_login', @level2type = N'COLUMN', @level2name = N'is_active';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'gives information on the last login date for the user.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_login', @level2type = N'COLUMN', @level2name = N'last_login_on';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Role Identifier linked to mp_roles.role_id - sourcing professional, rfq preparer, etc', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_login', @level2type = N'COLUMN', @level2name = N'role_id';


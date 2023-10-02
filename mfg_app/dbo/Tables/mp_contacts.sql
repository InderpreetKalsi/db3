CREATE TABLE [dbo].[mp_contacts] (
    [contact_id]                        INT            IDENTITY (1, 1) NOT NULL,
    [company_id]                        INT            NULL,
    [language_id]                       SMALLINT       NULL,
    [title]                             NVARCHAR (100) NULL,
    [first_name]                        NVARCHAR (100) NULL,
    [last_name]                         NVARCHAR (100) NULL,
    [contact_function]                  NVARCHAR (100) NULL,
    [is_buyer]                          BIT            NOT NULL,
    [is_admin]                          BIT            CONSTRAINT [DF__mp_contac__is_ad__1F98B2C1] DEFAULT ((1)) NOT NULL,
    [created_on]                        DATETIME       CONSTRAINT [DF__mp_contac__creat__47A6A41B] DEFAULT (getdate()) NULL,
    [modified_on]                       DATETIME       CONSTRAINT [DF__mp_contac__modif__489AC854] DEFAULT (getdate()) NULL,
    [address_id]                        INT            NULL,
    [record_origin_id]                  SMALLINT       CONSTRAINT [DF__mp_contac__recor__22751F6C] DEFAULT ((0)) NOT NULL,
    [incoterm_id]                       SMALLINT       CONSTRAINT [DF__mp_contac__incot__236943A5] DEFAULT ((0)) NOT NULL,
    [comments]                          NVARCHAR (MAX) NULL,
    [is_notify_by_email]                BIT            CONSTRAINT [DF__mp_contac__is_no__245D67DE] DEFAULT ((0)) NOT NULL,
    [is_mail_in_HTML]                   BIT            CONSTRAINT [DF__mp_contac__is_ma__25518C17] DEFAULT ((1)) NOT NULL,
    [show_deltailed_rating]             BIT            CONSTRAINT [DF__mp_contac__show___3493CFA7] DEFAULT ((0)) NOT NULL,
    [show_RFQ_award_stat]               BIT            CONSTRAINT [DF__mp_contac__show___3587F3E0] DEFAULT ((0)) NOT NULL,
    [user_id]                           NVARCHAR (450) NULL,
    [role_id]                           SMALLINT       NULL,
    [is_active]                         BIT            CONSTRAINT [DF__mp_contac__is_ac__69FBBC1F] DEFAULT ((1)) NOT NULL,
    [user_zoho_id]                      VARCHAR (200)  NULL,
    [zoho_user_status]                  INT            NULL,
    [contact_type_id]                   INT            DEFAULT ((0)) NULL,
    [Is_Validated_Buyer]                BIT            CONSTRAINT [DF_mp_contacts_Is_Validated_Buyer] DEFAULT ((0)) NULL,
    [last_login_on]                     DATETIME       NULL,
    [total_login_count]                 INT            NULL,
    [ms_booking_url]                    VARCHAR (500)  NULL,
    [SalesloftPeopleId]                 INT            NULL,
    [Is_External_Registration]          BIT            CONSTRAINT [DF_mp_contacts_Is_External_Registration] DEFAULT ((0)) NULL,
    [is_customer_rep]                   BIT            DEFAULT ((0)) NULL,
    [IsTestAccount]                     BIT            DEFAULT ((0)) NULL,
    [IpAddress]                         VARCHAR (100)  NULL,
    [VisionValidatedDate]               DATETIME       NULL,
    [HubSpotContactId]                  VARCHAR (255)  NULL,
    [IsOrderManagementChecked]          BIT            CONSTRAINT [DF_IsOrderManagementChecked] DEFAULT ((0)) NULL,
    [IsOrderManagementTileViewed]       BIT            CONSTRAINT [DF_IsOrderManagementTileViewed] DEFAULT ((0)) NULL,
    [StripeConnectID]                   VARCHAR (250)  NULL,
    [BuyerLastAwardingNotificationDate] DATETIME       NULL,
    CONSTRAINT [PK_mp_contacts] PRIMARY KEY CLUSTERED ([contact_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_contacts_mp_addresses] FOREIGN KEY ([address_id]) REFERENCES [dbo].[mp_addresses] ([address_id]),
    CONSTRAINT [FK_mp_contacts_mp_mst_roles] FOREIGN KEY ([role_id]) REFERENCES [dbo].[mp_mst_roles] ([role_id]),
    CONSTRAINT [fk_mp_contacts_mp_system_parameters] FOREIGN KEY ([zoho_user_status]) REFERENCES [dbo].[mp_system_parameters] ([id]),
    CONSTRAINT [FK_mp_contacts_To_mp_mst_incoterm] FOREIGN KEY ([incoterm_id]) REFERENCES [dbo].[mp_mst_incoterm] ([incoterm_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_contacts_01]
    ON [dbo].[mp_contacts]([company_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_contacts_is_buyer_company_id]
    ON [dbo].[mp_contacts]([is_buyer] ASC, [company_id] ASC)
    INCLUDE([address_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_contacts_is_buyer_IsTestAccount]
    ON [dbo].[mp_contacts]([is_buyer] ASC, [IsTestAccount] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_contacts_address_id]
    ON [dbo].[mp_contacts]([address_id] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_mp_contacts_is_buyer_created_on]
    ON [dbo].[mp_contacts]([is_buyer] ASC, [created_on] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contacts informations in a company(either it will be a buyer/Supplier/any other contacts created by Admin buyer and supplier etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'unique identifer of a contact ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'contact_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked company id in mp_company', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'company_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Default to 3- English', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'language_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Title like: Mr., Monsieur, Signor etc', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'title';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'First name of the contact', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'first_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'last name of the contact', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'last_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contact''s function like: Vice President, General Manager,Directeur general,Engineer,Marketing Manager,Commercial', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'contact_function';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 -  Contact will act as buyer, 0 - Contact will act as Supplier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'is_buyer';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Flag = 1 when the contact is administrator for the company', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'is_admin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'time stamp when record created', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'created_on';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'time stamp when record modified', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'modified_on';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked address id in mp_address', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'address_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_system_parameters.id', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'record_origin_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_incoterms.id', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'incoterm_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Freeform field for buyer / supplier where they can add a personal comment.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'comments';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1- Yes or 0 - No are the options, contact will be notified by email  depending on this option', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'is_notify_by_email';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Preferred email format', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'is_mail_in_HTML';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'this is the id column data from AspNetUsers Table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts', @level2type = N'COLUMN', @level2name = N'user_id';


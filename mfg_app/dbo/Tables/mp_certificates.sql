CREATE TABLE [dbo].[mp_certificates] (
    [certificate_id]          INT            IDENTITY (1, 1) NOT NULL,
    [certificate_code]        NVARCHAR (100) NULL,
    [certificate_description] NVARCHAR (MAX) NULL,
    [certificate_type_id]     SMALLINT       NOT NULL,
    [sort_number]             SMALLINT       NOT NULL,
    [upload_required]         BIT            NOT NULL,
    [company_id]              INT            NULL,
    [creation_date]           DATETIME       NULL,
    [creation_contact_id]     INT            NULL,
    [modify_date]             DATETIME       NULL,
    [modify_contact_id]       INT            NULL,
    [hide]                    BIT            NOT NULL,
    [hide_contact_id]         INT            NULL,
    [hide_date]               DATETIME       NULL,
    [ref_number_required]     BIT            NOT NULL,
    [exp_date_required]       BIT            NOT NULL,
    CONSTRAINT [PK_mp_certificates] PRIMARY KEY CLUSTERED ([certificate_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'when 1, File upload is required when certification in seleted by a company', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_certificates', @level2type = N'COLUMN', @level2name = N'upload_required';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Private certificate', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_certificates', @level2type = N'COLUMN', @level2name = N'company_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Creator cont id for private certificate', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_certificates', @level2type = N'COLUMN', @level2name = N'creation_contact_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Hide flag, 1 means hidden', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_certificates', @level2type = N'COLUMN', @level2name = N'hide';


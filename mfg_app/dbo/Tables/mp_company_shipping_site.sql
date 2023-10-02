CREATE TABLE [dbo].[mp_company_shipping_site] (
    [site_id]            INT            IDENTITY (1, 1) NOT NULL,
    [comp_id]            INT            NULL,
    [cont_id]            INT            DEFAULT ((0)) NOT NULL,
    [address_id]         INT            NOT NULL,
    [site_label]         NVARCHAR (350) DEFAULT ('') NULL,
    [default_site]       BIT            DEFAULT ((0)) NOT NULL,
    [site_creation_date] DATETIME       DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_mp_company_shipping_site] PRIMARY KEY CLUSTERED ([site_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_company_shipping_site_mp_addresses] FOREIGN KEY ([address_id]) REFERENCES [dbo].[mp_addresses] ([address_id])
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_company_shipping_site_default_site_comp_id]
    ON [dbo].[mp_company_shipping_site]([default_site] ASC, [comp_id] ASC)
    INCLUDE([address_id]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Site for a company', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_shipping_site';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'company id', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_shipping_site', @level2type = N'COLUMN', @level2name = N'comp_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'site owner (0 when the site is owned by the company)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_shipping_site', @level2type = N'COLUMN', @level2name = N'cont_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'address id linked to MP_ADDRESS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_company_shipping_site', @level2type = N'COLUMN', @level2name = N'address_id';


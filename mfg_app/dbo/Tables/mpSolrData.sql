CREATE TABLE [dbo].[mpSolrData] (
    [id]                    BIGINT         NOT NULL,
    [name]                  NVARCHAR (MAX) NULL,
    [company_logo_url]      NVARCHAR (MAX) NULL,
    [region_id]             NVARCHAR (MAX) NULL,
    [country_id]            NVARCHAR (MAX) NULL,
    [street_address]        NVARCHAR (MAX) NULL,
    [city]                  NVARCHAR (MAX) NULL,
    [number_of_employees]   NVARCHAR (MAX) NULL,
    [rating]                NVARCHAR (MAX) NULL,
    [creation_date]         NVARCHAR (MAX) NULL,
    [supplier_type_3]       NVARCHAR (MAX) NULL,
    [zip_code]              NVARCHAR (MAX) NULL,
    [industry_tag]          NVARCHAR (MAX) NULL,
    [equipment_tag]         NVARCHAR (MAX) NULL,
    [capabilities]          NVARCHAR (MAX) NULL,
    [discipline_name_3]     NVARCHAR (MAX) NULL,
    [region]                NVARCHAR (MAX) NULL,
    [country]               NVARCHAR (MAX) NULL,
    [description_3]         NVARCHAR (MAX) NULL,
    [seo_description_3]     NVARCHAR (MAX) NULL,
    [seo_title_3]           NVARCHAR (MAX) NULL,
    [primary_contact_name]  NVARCHAR (MAX) NULL,
    [primary_contact_title] NVARCHAR (MAX) NULL,
    [contact_image_url]     NVARCHAR (MAX) NULL,
    [phone]                 NVARCHAR (MAX) NULL,
    [fax]                   NVARCHAR (MAX) NULL,
    [website_url]           NVARCHAR (MAX) NULL,
    [email]                 VARCHAR (500)  NULL,
    [duns]                  NVARCHAR (MAX) NULL,
    [cage]                  NVARCHAR (MAX) NULL,
    [company_banner_url]    NVARCHAR (MAX) NULL,
    [language]              NVARCHAR (MAX) NULL,
    [is_exists_in_mfg]      BIT            DEFAULT ((0)) NULL,
    [isincludedinxml]       BIT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_mpSolrData] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_mpSolrData_id_email]
    ON [dbo].[mpSolrData]([id] ASC, [email] ASC) WITH (FILLFACTOR = 90);


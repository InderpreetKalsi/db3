CREATE TABLE [dbo].[mp_contacts_prefcountry] (
    [contacts_prefcountry_id]     INT      IDENTITY (1, 1) NOT NULL,
    [cont_id]                     INT      NOT NULL,
    [country_id]                  SMALLINT NOT NULL,
    [territory_classification_id] SMALLINT NULL,
    [region_id]                   SMALLINT NULL,
    CONSTRAINT [PK_mp_contacts_prefcountry_1] PRIMARY KEY CLUSTERED ([contacts_prefcountry_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_contacts_prefcountry_mp_contacts] FOREIGN KEY ([cont_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_contacts_prefcountry_mp_mst_territory_classification] FOREIGN KEY ([territory_classification_id]) REFERENCES [dbo].[mp_mst_territory_classification] ([territory_classification_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'list all preferred country. linked contact and country!  This is created during user registration.  The user is given the option to choose what sizes they work with, what countries they prefer to work with, etc.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_contacts_prefcountry';


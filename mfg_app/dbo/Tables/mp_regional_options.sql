CREATE TABLE [dbo].[mp_regional_options] (
    [regional_id] INT          IDENTITY (1, 1) NOT NULL,
    [cont_id]     INT          NULL,
    [comp_id]     INT          NULL,
    [time_format] NVARCHAR (3) DEFAULT ('12h') NULL,
    [created_on]  DATETIME     DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_mp_regional_options] PRIMARY KEY CLUSTERED ([regional_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_regional_options_mp_contacts] FOREIGN KEY ([cont_id]) REFERENCES [dbo].[mp_contacts] ([contact_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Regional options for a contact.  Used in Enterprise but hidden in Marketplace.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_regional_options';


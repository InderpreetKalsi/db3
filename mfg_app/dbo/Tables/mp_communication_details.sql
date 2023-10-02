CREATE TABLE [dbo].[mp_communication_details] (
    [communication_id]          INT            IDENTITY (1, 1) NOT NULL,
    [communication_type_id]     SMALLINT       NOT NULL,
    [company_id]                INT            NULL,
    [contact_id]                INT            NULL,
    [communication_value]       NVARCHAR (150) NULL,
    [is_valid]                  BIT            NOT NULL,
    [communication_clean_value] NVARCHAR (150) NULL,
    [country_code]              VARCHAR (50)   NULL,
    CONSTRAINT [PK_mp_communication_details] PRIMARY KEY CLUSTERED ([communication_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_communication_details_mp_contacts] FOREIGN KEY ([contact_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_communication_details_To_mp_mst_communication_types] FOREIGN KEY ([communication_type_id]) REFERENCES [dbo].[mp_mst_communication_types] ([communication_type_id])
);


GO
CREATE NONCLUSTERED INDEX [idx_mp_communication_details_communication_type_id]
    ON [dbo].[mp_communication_details]([communication_type_id] ASC)
    INCLUDE([contact_id]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_communication_details_communication_type_id_contact_id]
    ON [dbo].[mp_communication_details]([communication_type_id] ASC, [contact_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_communication_details_communication_type_id_contact_id_communication_value]
    ON [dbo].[mp_communication_details]([communication_type_id] ASC)
    INCLUDE([contact_id], [communication_value]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Phone,Email,Fax,URL for a contact or a company', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_communication_details';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'COLUMN TO HOLD CLEAN PHONE AND FAX NUMBER, UPDATED BY TRIGGER SP_DEVICE.TRSP_DEVICE_CLEAN_DATA', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_communication_details', @level2type = N'COLUMN', @level2name = N'communication_clean_value';


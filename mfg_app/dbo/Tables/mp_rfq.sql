CREATE TABLE [dbo].[mp_rfq] (
    [rfq_id]                                    INT              IDENTITY (1, 1) NOT NULL,
    [rfq_name]                                  NVARCHAR (100)   NULL,
    [rfq_description]                           NVARCHAR (MAX)   NULL,
    [contact_id]                                INT              NULL,
    [rfq_created_on]                            DATETIME         NULL,
    [rfq_status_id]                             SMALLINT         NULL,
    [is_special_certifications_by_manufacturer] BIT              NOT NULL,
    [is_special_instruction_to_manufacturer]    BIT              NOT NULL,
    [special_instruction_to_manufacturer]       NVARCHAR (MAX)   NULL,
    [importance_price]                          SMALLINT         NULL,
    [importance_speed]                          SMALLINT         NULL,
    [importance_quality]                        SMALLINT         NULL,
    [Quotes_needed_by]                          DATETIME         NULL,
    [award_date]                                DATETIME         NULL,
    [is_partial_quoting_allowed]                BIT              NOT NULL,
    [Who_Pays_for_Shipping]                     SMALLINT         NULL,
    [ship_to]                                   INT              NULL,
    [is_register_supplier_quote_the_RFQ]        BIT              NOT NULL,
    [pref_NDA_Type]                             SMALLINT         NULL,
    [Post_Production_Process_id]                INT              NULL,
    [Imported_Data]                             BIT              NULL,
    [sourcing_advisor_id]                       INT              NULL,
    [rfq_zoho_id]                               VARCHAR (200)    NULL,
    [file_id]                                   INT              NULL,
    [ModifiedBy]                                INT              NULL,
    [payment_term_id]                           INT              NULL,
    [rfq_guid]                                  UNIQUEIDENTIFIER CONSTRAINT [DF_mp_rfq_rfq_guid] DEFAULT (newid()) ROWGUIDCOL NOT NULL,
    [pref_rfq_communication_method]             INT              NULL,
    [rfq_quality]                               INT              NULL,
    [ExcludeFromDashboardAwardedModule]         BIT              DEFAULT ((0)) NULL,
    [rfq_purpose_id]                            INT              NULL,
    [IsMfgCommunityRfq]                         BIT              DEFAULT ((0)) NULL,
    [IsCommunityRfqReleased]                    BIT              DEFAULT ((0)) NULL,
    [IsCommunityRfqClosed]                      BIT              DEFAULT ((0)) NULL,
    [CommunityRfqReleaseDate]                   DATETIME         NULL,
    [CommunityRfqReleaseBy]                     INT              NULL,
    [CommunityRfqClosedDate]                    DATETIME         NULL,
    [CommunityRfqClosedBy]                      INT              NULL,
    [IsArchived]                                BIT              DEFAULT ((0)) NULL,
    [RegenerateShopIQOn]                        DATETIME         NULL,
    [WillDoLater]                               BIT              DEFAULT ((0)) NULL,
    [DeliveryDate]                              DATETIME         NULL,
    [IsRfqWithMissingInfo]                      BIT              NULL,
    [WithOrderManagement]                       BIT              CONSTRAINT [DF_WithOrderManagement] DEFAULT ((1)) NULL,
    [InvoiceCreated]                            BIT              CONSTRAINT [DF_mp_rfq_InvoiceCreated] DEFAULT ((0)) NULL,
    [RfqEncryptedId]                            VARCHAR (100)    NULL,
    [IsReshapeFileProcessed]                    BIT              NULL,
    CONSTRAINT [PK_mp_rfq] PRIMARY KEY CLUSTERED ([rfq_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_mp_company_shipping_site] FOREIGN KEY ([ship_to]) REFERENCES [dbo].[mp_company_shipping_site] ([site_id]) NOT FOR REPLICATION,
    CONSTRAINT [FK_mp_rfq_mp_contacts] FOREIGN KEY ([contact_id]) REFERENCES [dbo].[mp_contacts] ([contact_id]),
    CONSTRAINT [FK_mp_rfq_mp_mst_incoterm] FOREIGN KEY ([Who_Pays_for_Shipping]) REFERENCES [dbo].[mp_mst_incoterm] ([incoterm_id]),
    CONSTRAINT [FK_mp_rfq_mp_mst_NDAType] FOREIGN KEY ([pref_NDA_Type]) REFERENCES [dbo].[mp_mst_NDAType] ([NDA_type_id]),
    CONSTRAINT [FK_mp_rfq_mp_mst_rfq_buyerStatus] FOREIGN KEY ([rfq_status_id]) REFERENCES [dbo].[mp_mst_rfq_buyerStatus] ([rfq_buyerstatus_id]),
    CONSTRAINT [FK_mp_rfq_mp_system_parameters] FOREIGN KEY ([Post_Production_Process_id]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


GO
CREATE NONCLUSTERED INDEX [IDX_mp_rfq_rfq_status_id]
    ON [dbo].[mp_rfq]([rfq_status_id] ASC)
    INCLUDE([rfq_name], [contact_id], [rfq_created_on], [Quotes_needed_by], [award_date], [file_id], [payment_term_id], [special_instruction_to_manufacturer]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NC_IDX_mp_rfq_contact_id]
    ON [dbo].[mp_rfq]([contact_id] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_rfq_IsMfgCommunityRfq,rfq_status_id]
    ON [dbo].[mp_rfq]([IsMfgCommunityRfq] ASC, [rfq_status_id] ASC)
    INCLUDE([rfq_created_on]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'this is status_id from mp_mst_status table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'rfq_status_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'"1 - High Importance
2- Middle importance
3 -low importance"', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'importance_price';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'"1 - High Importance
2- Middle importance
3 -low importance"', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'importance_speed';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'"1 - High Importance
2- Middle importance
3 -low importance"', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'importance_quality';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'"This will holds the Incoterm_id from mp_mst_incoterm table.

INCOTERM_EXW - buyer pays - http://www.worldclassshipping.com/incoterm_exw.html
INCOTERM_DDP - seller pays - http://www.worldclassshipping.com/incoterm_ddp.html"', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'Who_Pays_for_Shipping';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Shipping address id from [mp_company_shipping_site].[site_id]', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'ship_to';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'"If this column set to 
0  - then you will find the selected supplier in mp_rfq_supplier table, 
1 - There will be no data to mp_rfq_supplier table and will consider all the register supplier in the system as per selected region."', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'is_register_supplier_quote_the_RFQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'it will store NDA_type_id from mp_mst_NDAType table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'pref_NDA_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is a new implementation and Eddie needs to provide input on this.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'Post_Production_Process_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Data import use only, do not use this in Application', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq', @level2type = N'COLUMN', @level2name = N'Imported_Data';


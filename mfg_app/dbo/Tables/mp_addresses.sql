CREATE TABLE [dbo].[mp_addresses] (
    [address_id]            INT            IDENTITY (1, 1) NOT NULL,
    [country_id]            SMALLINT       NOT NULL,
    [region_id]             SMALLINT       NOT NULL,
    [address1]              NVARCHAR (510) NULL,
    [address2]              NVARCHAR (510) NULL,
    [address3]              NVARCHAR (510) NULL,
    [address4]              NVARCHAR (510) NULL,
    [address5]              NVARCHAR (510) NULL,
    [show_in_profile]       BIT            NOT NULL,
    [show_only_state_city]  BIT            NOT NULL,
    [is_active]             BIT            CONSTRAINT [DF_mp_addresses_is_active] DEFAULT ((1)) NULL,
    [is_geocode_data_added] BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_addresses] PRIMARY KEY CLUSTERED ([address_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_addresses_To_country_id] FOREIGN KEY ([country_id]) REFERENCES [dbo].[mp_mst_country] ([country_id]),
    CONSTRAINT [FK_mp_addresses_To_mp_mst_region] FOREIGN KEY ([region_id]) REFERENCES [dbo].[mp_mst_region] ([REGION_ID])
);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_addresses_country_id]
    ON [dbo].[mp_addresses]([country_id] ASC) WITH (FILLFACTOR = 90);


CREATE TABLE [dbo].[mp_mst_contact_type] (
    [contact_type_id]          INT           IDENTITY (1, 1) NOT NULL,
    [contact_type_name]        VARCHAR (150) NULL,
    [contact_type_description] VARCHAR (250) NULL,
    [for_buyer]                BIT           NULL,
    [for_supplier]             BIT           NULL,
    [status_id]                INT           NULL,
    [sort_order]               INT           NULL,
    [creation_date]            DATETIME      NULL,
    [modification_date]        DATETIME      NULL,
    CONSTRAINT [pk_mp_mst_contact_type_contact_type_id] PRIMARY KEY CLUSTERED ([contact_type_id] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_mst_certificate_types] (
    [certificate_type_id]     SMALLINT      IDENTITY (1, 1) NOT NULL,
    [certificate_type_li_key] VARCHAR (200) NOT NULL,
    [description]             VARCHAR (50)  NOT NULL,
    [sort_order]              SMALLINT      NULL,
    [hide]                    BIT           NULL,
    CONSTRAINT [pk_mp_mst_certificate_types] PRIMARY KEY CLUSTERED ([certificate_type_id] ASC) WITH (FILLFACTOR = 90)
);


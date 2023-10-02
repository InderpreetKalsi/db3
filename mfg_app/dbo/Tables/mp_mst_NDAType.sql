CREATE TABLE [dbo].[mp_mst_NDAType] (
    [NDA_type_id]          SMALLINT     IDENTITY (1, 1) NOT NULL,
    [NDA_Type_key]         VARCHAR (50) NOT NULL,
    [NDA_type_description] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_mp_mst_NDAType] PRIMARY KEY CLUSTERED ([NDA_type_id] ASC) WITH (FILLFACTOR = 90)
);


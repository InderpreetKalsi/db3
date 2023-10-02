CREATE TABLE [dbo].[mp_mst_dictionary] (
    [li_id]       INT            IDENTITY (1, 1) NOT NULL,
    [li_key]      VARCHAR (200)  NULL,
    [li_fr]       NVARCHAR (MAX) NULL,
    [li_de]       NVARCHAR (MAX) NULL,
    [li_it]       NVARCHAR (MAX) NULL,
    [li_en]       NVARCHAR (MAX) NULL,
    [li_sp]       NVARCHAR (MAX) NULL,
    [li_pt]       NVARCHAR (MAX) NULL,
    [li_cz]       NVARCHAR (MAX) NULL,
    [li_hg]       NVARCHAR (MAX) NULL,
    [li_us]       NVARCHAR (MAX) NULL,
    [li_cn]       NVARCHAR (MAX) NULL,
    [li_tr]       NVARCHAR (MAX) NULL,
    [li_ko]       NVARCHAR (MAX) NULL,
    [li_vi]       NVARCHAR (MAX) NULL,
    [li_jp]       NVARCHAR (MAX) NULL,
    [used]        BIT            NULL,
    [modified_on] DATETIME       NULL,
    [created_on]  SMALLDATETIME  NULL,
    CONSTRAINT [PK_mp_mst_dictionary] PRIMARY KEY CLUSTERED ([li_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_NONCLUSTERED_mp_mst_dictionary_20180905_01]
    ON [dbo].[mp_mst_dictionary]([li_key] ASC)
    INCLUDE([li_en]) WITH (FILLFACTOR = 90);


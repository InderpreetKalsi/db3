CREATE TABLE [dbo].[mp_mst_supplier_type] (
    [supplier_type_id]         INT           IDENTITY (1, 1) NOT NULL,
    [supplier_type_name]       VARCHAR (50)  NOT NULL,
    [supplier_type_name_en]    VARCHAR (150) NULL,
    [industry_id]              SMALLINT      NOT NULL,
    [block_usersite_selection] BIT           NOT NULL,
    CONSTRAINT [PK_mp_mst_supplier_type] PRIMARY KEY CLUSTERED ([supplier_type_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'when 1, the user site can''t change anymore his supplier type selection', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_supplier_type', @level2type = N'COLUMN', @level2name = N'block_usersite_selection';


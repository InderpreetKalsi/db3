CREATE TABLE [dbo].[mp_mst_incoterm] (
    [incoterm_id]     SMALLINT      IDENTITY (1, 1) NOT NULL,
    [incoterm_code]   CHAR (3)      NOT NULL,
    [incoterm_name]   VARCHAR (50)  NOT NULL,
    [description]     VARCHAR (100) NOT NULL,
    [incoterm_li_key] VARCHAR (50)  NOT NULL,
    [status_id]       SMALLINT      DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mp_mst_incoterm] PRIMARY KEY CLUSTERED ([incoterm_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Incoterm identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_incoterm', @level2type = N'COLUMN', @level2name = N'incoterm_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'DB internal use name, use INCOTERM_LI_KEY for App use', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_incoterm', @level2type = N'COLUMN', @level2name = N'incoterm_name';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Token for full description', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_incoterm', @level2type = N'COLUMN', @level2name = N'description';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'token for incoterm name', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_incoterm', @level2type = N'COLUMN', @level2name = N'incoterm_li_key';


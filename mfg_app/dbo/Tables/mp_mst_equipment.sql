CREATE TABLE [dbo].[mp_mst_equipment] (
    [equipment_Id]   INT            IDENTITY (1, 1) NOT NULL,
    [equipment_Text] NVARCHAR (MAX) NULL,
    [TagSourceID]    BIT            NOT NULL,
    [CreateDate]     DATETIME2 (7)  NOT NULL,
    [UpdateDate]     DATETIME2 (7)  NOT NULL,
    [Status_ID]      INT            NOT NULL,
    [FileId]         INT            NULL,
    CONSTRAINT [PK_mp_mst_equipment] PRIMARY KEY CLUSTERED ([equipment_Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_mst_equipment_mp_special_files] FOREIGN KEY ([FileId]) REFERENCES [dbo].[mp_special_files] ([FILE_ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'0 = MFG pre-seeded tag; 1 = user-created tag', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_equipment', @level2type = N'COLUMN', @level2name = N'TagSourceID';


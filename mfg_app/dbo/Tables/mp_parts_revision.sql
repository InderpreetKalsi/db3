CREATE TABLE [dbo].[mp_parts_revision] (
    [part_revision_id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [part_id]          BIGINT         NOT NULL,
    [field]            NVARCHAR (400) NOT NULL,
    [oldvalue]         NVARCHAR (MAX) NULL,
    [newvalue]         NVARCHAR (MAX) NULL,
    [creation_date]    DATETIME       NOT NULL,
    [parts_version_id] BIGINT         NOT NULL,
    CONSTRAINT [PK_mp_parts_revision] PRIMARY KEY CLUSTERED ([part_revision_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_parts_revision_mp_parts] FOREIGN KEY ([part_id]) REFERENCES [dbo].[mp_parts] ([part_id]),
    CONSTRAINT [FK_mp_parts_revision_mp_parts_versions] FOREIGN KEY ([parts_version_id]) REFERENCES [dbo].[mp_parts_versions] ([parts_version_id])
);


GO
ALTER TABLE [dbo].[mp_parts_revision] NOCHECK CONSTRAINT [FK_mp_parts_revision_mp_parts_versions];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'linked to mp_parts_versions table', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_parts_revision', @level2type = N'COLUMN', @level2name = N'parts_version_id';


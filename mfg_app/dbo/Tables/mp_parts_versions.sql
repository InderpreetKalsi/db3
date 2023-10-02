CREATE TABLE [dbo].[mp_parts_versions] (
    [parts_version_id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [contact_id]       INT          NOT NULL,
    [major_number]     INT          NOT NULL,
    [minor_number]     INT          NOT NULL,
    [version_number]   VARCHAR (61) NULL,
    [creation_date]    DATETIME     NOT NULL,
    [part_ID]          INT          NULL,
    CONSTRAINT [PK_mp_parts_versions] PRIMARY KEY CLUSTERED ([parts_version_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_parts_versions_mp_contacts] FOREIGN KEY ([contact_id]) REFERENCES [dbo].[mp_contacts] ([contact_id])
);


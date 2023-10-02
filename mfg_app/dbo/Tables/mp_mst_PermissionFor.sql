CREATE TABLE [dbo].[mp_mst_PermissionFor] (
    [Id]          INT           IDENTITY (101, 1) NOT NULL,
    [Element]     VARCHAR (250) NULL,
    [Key]         VARCHAR (250) NULL,
    [Description] VARCHAR (250) NULL,
    [IsRemove]    BIT           DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


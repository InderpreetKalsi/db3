CREATE TABLE [dbo].[mp_mst_Privilages] (
    [Id]           INT           IDENTITY (1001, 1) NOT NULL,
    [ElementID]    INT           NULL,
    [PrivilegeTo]  VARCHAR (250) NULL,
    [Key]          VARCHAR (250) NULL,
    [DefaultValue] BIT           DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


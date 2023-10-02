CREATE TABLE [dbo].[mp_mst_part_drawer_questions] (
    [Id]             INT           IDENTITY (101, 1) NOT NULL,
    [PartCategoryId] INT           NULL,
    [Questions]      VARCHAR (500) NULL,
    [IsActive]       BIT           DEFAULT ((1)) NULL,
    CONSTRAINT [pk_mp_mst_part_drawer_questions_Id_PartCategoryId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


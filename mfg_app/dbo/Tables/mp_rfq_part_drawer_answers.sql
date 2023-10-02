CREATE TABLE [dbo].[mp_rfq_part_drawer_answers] (
    [Id]         INT           IDENTITY (101, 1) NOT NULL,
    [RfqPartId]  INT           NULL,
    [PartId]     INT           NULL,
    [QuestionId] INT           NOT NULL,
    [Answer]     VARCHAR (250) NULL,
    [CreatedOn]  DATETIME      DEFAULT (getutcdate()) NULL,
    CONSTRAINT [pk_mp_rfq_part_drawer_answers_Id_RfqPartId_QuestionId] PRIMARY KEY CLUSTERED ([Id] ASC, [QuestionId] ASC) WITH (FILLFACTOR = 90)
);


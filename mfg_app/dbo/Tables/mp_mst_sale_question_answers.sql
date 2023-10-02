CREATE TABLE [dbo].[mp_mst_sale_question_answers] (
    [id]          INT           IDENTITY (101, 1) NOT NULL,
    [description] VARCHAR (500) NULL,
    [parent_id]   INT           NULL,
    [is_answer]   BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [pk_mp_mst_sale_question_answers_id] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


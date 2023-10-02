CREATE TABLE [dbo].[mp_mst_Survey_QuestionInfo] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [SurveyInfoID]     INT            NOT NULL,
    [SurveyQuestionID] INT            NOT NULL,
    [Title]            NVARCHAR (200) NULL,
    [BaseType]         NVARCHAR (50)  NULL,
    [Type]             NVARCHAR (50)  NULL,
    CONSTRAINT [PK_mp_mst_Survey_QuestionInfo] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_mst_Survey_QuestionInfo_mp_mst_SurveyInfo] FOREIGN KEY ([SurveyInfoID]) REFERENCES [dbo].[mp_mst_SurveyInfo] ([ID]) ON DELETE CASCADE ON UPDATE CASCADE
);


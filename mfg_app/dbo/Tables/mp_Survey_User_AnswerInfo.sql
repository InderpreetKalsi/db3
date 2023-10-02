CREATE TABLE [dbo].[mp_Survey_User_AnswerInfo] (
    [ID]                   INT            IDENTITY (1, 1) NOT NULL,
    [UserID]               NVARCHAR (450) NOT NULL,
    [SurveyQuestionInfoID] INT            NOT NULL,
    [SurveyResponseID]     INT            NOT NULL,
    [Answer]               NVARCHAR (200) NULL,
    [Status]               NVARCHAR (50)  NULL,
    [AnswerID]             NVARCHAR (200) NULL,
    [StartedDate]          DATETIME       NULL,
    [SubmittedDate]        DATETIME       NULL,
    CONSTRAINT [PK_mp_Survey_User_AnswerInfo] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_Survey_User_AnswerInfo_mp_mst_Survey_QuestionInfo] FOREIGN KEY ([SurveyQuestionInfoID]) REFERENCES [dbo].[mp_mst_Survey_QuestionInfo] ([ID]) ON DELETE CASCADE ON UPDATE CASCADE
);


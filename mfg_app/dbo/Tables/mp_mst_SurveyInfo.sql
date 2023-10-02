CREATE TABLE [dbo].[mp_mst_SurveyInfo] (
    [ID]        INT            IDENTITY (1, 1) NOT NULL,
    [SurveyID]  NVARCHAR (150) NOT NULL,
    [Key]       NVARCHAR (50)  NOT NULL,
    [Title]     NVARCHAR (200) NULL,
    [Type]      NVARCHAR (50)  NULL,
    [Status]    NVARCHAR (50)  NULL,
    [CreatedOn] DATETIME       NULL,
    CONSTRAINT [PK_mp_mst_SurveyInfo] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


CREATE TABLE [dbo].[mp_nps_api_responses] (
    [id]                INT            NOT NULL,
    [contact_id]        BIGINT         NOT NULL,
    [person]            VARCHAR (50)   NULL,
    [survey_type]       VARCHAR (50)   NULL,
    [score]             TINYINT        NULL,
    [comment]           NVARCHAR (500) NULL,
    [permalink]         NVARCHAR (400) NULL,
    [created_at]        DATETIME       NULL,
    [updated_at]        DATETIME       NULL,
    [person_properties] NVARCHAR (MAX) NULL,
    [notes]             NVARCHAR (MAX) NULL,
    [tags]              NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_mp_nps_api_responses] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);


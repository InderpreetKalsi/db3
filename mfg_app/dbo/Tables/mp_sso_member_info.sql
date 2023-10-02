CREATE TABLE [dbo].[mp_sso_member_info] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [KeyID]            INT            NOT NULL,
    [UserID]           NVARCHAR (255) NOT NULL,
    [SignupID]         NVARCHAR (50)  NOT NULL,
    [Email]            NVARCHAR (500) NOT NULL,
    [UserLogin]        NVARCHAR (500) NOT NULL,
    [ActivationKey]    NVARCHAR (500) NOT NULL,
    [CreatedOn]        DATETIME       NOT NULL,
    [CreatedFromIP]    NVARCHAR (50)  NOT NULL,
    [ActivatedOn]      DATETIME       NULL,
    [ActivationFromIP] NVARCHAR (50)  NULL,
    [MemberId]         INT            NULL,
    CONSTRAINT [PK_mp_sso_member_info] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


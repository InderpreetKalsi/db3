CREATE TABLE [dbo].[mp_sso_auth_info] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [KeyID]         INT            NOT NULL,
    [UserID]        NVARCHAR (255) NOT NULL,
    [Email]         NVARCHAR (500) NULL,
    [Token]         NVARCHAR (MAX) NULL,
    [GrantType]     NVARCHAR (50)  NOT NULL,
    [CreatedOn]     DATETIME       NOT NULL,
    [CreatedFromIP] NVARCHAR (50)  NOT NULL,
    [JWTToken]      NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_mp_sso_auth_info] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


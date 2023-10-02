CREATE TABLE [dbo].[mp_user_social_media_account] (
    [Id]                INT            IDENTITY (101, 1) NOT NULL,
    [AspNetUserId]      NVARCHAR (900) NOT NULL,
    [SocialMediaTypeId] INT            NOT NULL,
    [SocialMediaId]     VARCHAR (250)  NULL,
    [IsActive]          BIT            DEFAULT ((1)) NULL,
    [CreatedOn]         DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedOn]        DATETIME       NULL,
    CONSTRAINT [pk_mp_user_social_media_account_Id_AspNetUserId_SocialMediaTypeId] PRIMARY KEY CLUSTERED ([AspNetUserId] ASC, [Id] ASC, [SocialMediaTypeId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [fk_mp_user_social_media_account_mp_system_parameters_SocialMediaTypeId_Id] FOREIGN KEY ([SocialMediaTypeId]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


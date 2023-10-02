CREATE TABLE [dbo].[AspNetUsers] (
    [Id]                   NVARCHAR (450)     NOT NULL,
    [AccessFailedCount]    INT                DEFAULT ((0)) NOT NULL,
    [ConcurrencyStamp]     NVARCHAR (MAX)     NULL,
    [Email]                NVARCHAR (256)     NULL,
    [EmailConfirmed]       BIT                DEFAULT ((0)) NOT NULL,
    [FacebookId]           BIGINT             NULL,
    [FirstName]            NVARCHAR (MAX)     NULL,
    [LastName]             NVARCHAR (MAX)     NULL,
    [LockoutEnabled]       BIT                DEFAULT ((0)) NOT NULL,
    [LockoutEnd]           DATETIMEOFFSET (7) NULL,
    [NormalizedEmail]      NVARCHAR (256)     NULL,
    [NormalizedUserName]   NVARCHAR (256)     NULL,
    [PasswordHash]         NVARCHAR (MAX)     NULL,
    [PhoneNumber]          NVARCHAR (MAX)     NULL,
    [PhoneNumberConfirmed] BIT                DEFAULT ((0)) NOT NULL,
    [PictureUrl]           NVARCHAR (MAX)     NULL,
    [SecurityStamp]        NVARCHAR (MAX)     NULL,
    [TwoFactorEnabled]     BIT                DEFAULT ((0)) NOT NULL,
    [UserName]             NVARCHAR (256)     NULL,
    [contact_id]           INT                NULL,
    [PasswordOld]          NVARCHAR (MAX)     NULL,
    [last_ogin]            DATETIME           NULL,
    [is_pulse_user]        BIT                DEFAULT ((0)) NOT NULL,
    [VerifiedOn]           DATETIME           NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [EmailIndex]
    ON [dbo].[AspNetUsers]([NormalizedEmail] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Internal use only: It will hold the cont_id from sp_cont table and will be used for updating mp_contact table User_id', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'AspNetUsers', @level2type = N'COLUMN', @level2name = N'contact_id';


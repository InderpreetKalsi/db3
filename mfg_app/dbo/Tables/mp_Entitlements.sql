CREATE TABLE [dbo].[mp_Entitlements] (
    [Id]           INT            IDENTITY (10001, 1) NOT NULL,
    [RoleID]       NVARCHAR (900) NULL,
    [PrivilegeID]  INT            NULL,
    [DefaultValue] BIT            DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


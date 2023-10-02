CREATE TABLE [dbo].[mp_zohoo_oauthtokens] (
    [useridentifier] VARCHAR (150)  NULL,
    [accesstoken]    VARCHAR (MAX)  NULL,
    [expirytime]     BIGINT         NULL,
    [refreshtoken]   NVARCHAR (MAX) NULL
);


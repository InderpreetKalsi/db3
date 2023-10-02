CREATE TABLE [dbo].[mp_refresh_token] (
    [Id]     INT            IDENTITY (1, 1) NOT NULL,
    [Token]  NVARCHAR (450) NULL,
    [UserId] NVARCHAR (450) NULL,
    [IsStop] BIT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


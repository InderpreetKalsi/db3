CREATE TABLE [dbo].[mpUserRegistrationCaptureIpAddressLogs] (
    [Id]            INT           IDENTITY (1, 1) NOT NULL,
    [EmailId]       VARCHAR (100) NOT NULL,
    [IpAddress]     VARCHAR (100) NULL,
    [Status]        VARCHAR (100) NULL,
    [LogDate]       DATETIME      DEFAULT (getutcdate()) NULL,
    [RecapchaScore] VARCHAR (100) NULL,
    CONSTRAINT [PK_mpUserRegistrationIpAddressLogs_Id_EmailId] PRIMARY KEY CLUSTERED ([Id] ASC, [EmailId] ASC) WITH (FILLFACTOR = 90)
);


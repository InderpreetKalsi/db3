CREATE TABLE [dbo].[mpListofInvalidPhoneNos] (
    [Id]          INT          IDENTITY (1, 1) NOT NULL,
    [PhoneNumber] VARCHAR (10) NULL,
    CONSTRAINT [PK_Id_mpListofInvalidPhoneNos] PRIMARY KEY CLUSTERED ([Id] ASC)
);


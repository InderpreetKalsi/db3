CREATE TABLE [dbo].[mpNewTermAcceptances] (
    [id]                       INT            IDENTITY (1, 1) NOT NULL,
    [Email]                    NVARCHAR (512) NOT NULL,
    [Is_Acceptances]           BIT            NULL,
    [Created_On]               DATETIME       NULL,
    [Who_Accepted_Or_Declined] BIT            NULL,
    [Contact_Id]               INT            NULL,
    [is_buyer]                 BIT            NULL,
    [Modify_On]                DATETIME       NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


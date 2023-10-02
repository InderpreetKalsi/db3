CREATE TABLE [dbo].[mp_email_change_logs] (
    [Id]         INT           IDENTITY (1, 1) NOT NULL,
    [OldEmail]   VARCHAR (250) NULL,
    [NewEmail]   VARCHAR (250) NULL,
    [ModifiedBy] INT           NULL,
    [ModifiedOn] DATETIME      DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_mp_email_change_logs_Id] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);


GO

CREATE TRIGGER [dbo].trImmediateUpdateEmailInHubSpotdB 
ON [dbo].mp_email_change_logs  
AFTER INSERT
AS
BEGIN
	DECLARE @OldEmail VARCHAR(500)
	DECLARE @NewEmail VARCHAR(500)

	SELECT 
		@OldEmail = OldEmail
		,@NewEmail = NewEmail 
	FROM inserted

	UPDATE [DataSync_MarketplaceHubSpot]..HubSpotContacts 
	SET
		Email = @NewEmail
		,IsSynced = 0
		,IsProcessed = NULL
	WHERE Email = @OldEmail

END
GO
DISABLE TRIGGER [dbo].[trImmediateUpdateEmailInHubSpotdB]
    ON [dbo].[mp_email_change_logs];


/*

EXEC proc_set_HubSpotContactsCreatedOrUpdatedLogs
    @HubSpotContactsIdentityKeyId = 2030
	,@HubSpotContactId = '16940694668'
	,@IsProcessed = 1
	,@IsSynced = 1
	,@ProcessedDate = '2023-08-17 08:13:34.487'
	,@SyncedDate = '2023-08-17 08:13:34.487'

hubspotcontactscreatedorupdatedlogs -> TransactionStatus -> 0 - Insert
															1 - Update


*/
  
 
CREATE PROCEDURE [dbo].[proc_set_HubSpotContactsCreatedOrUpdatedLogs]
(
	@HubSpotContactsIdentityKeyId	INT 
	,@HubSpotContactId VARCHAR(255) = NULL
	,@IsProcessed	  BIT 			
	,@IsSynced		  BIT 			
	,@ProcessedDate   DATETIME  
	,@SyncedDate      DATETIME = NULL
)
AS
BEGIN

DECLARE @identity bigint = 0

BEGIN TRY
----- insert record into log table
		INSERT INTO hubspotcontactscreatedorupdatedlogs
					(
					 hubspotcontactsidentitykeyid,
					 hubspotcontactid,
					 isprocessed,
					 issynced,
					 processeddate,
					 synceddate
					 )
		VALUES      (
		             @HubSpotContactsIdentityKeyId,
					 @HubSpotContactId,
					 @IsProcessed,
					 @IsSynced,
					 @ProcessedDate,
					 @SyncedDate
					 ) 

		SET @identity = @@identity

	BEGIN TRANSACTION
	
		IF @identity > 0
		BEGIN
			----update HubSpotContacts 
			UPDATE HubSpotContacts
			SET [HubSpot Contact Id] = @HubSpotContactId
			,IsSynced                = @IsSynced
			,IsProcessed             = @IsProcessed
			,SyncedDate				 = @SyncedDate
			,ProcessedDate			 = @ProcessedDate
			WHERE Id                 = @HubSpotContactsIdentityKeyId

			IF (SELECT COUNT(1) FROM hubspotcontacts(NOLOCK) WHERE id  = @HubSpotContactsIdentityKeyId AND IsSynced = 1 AND IsProcessed = 1) > 0
			BEGIN
				---update hubspotcontactscreatedorupdatedlogs
				UPDATE hubspotcontactscreatedorupdatedlogs
				SET TransactionStatus = 1
				WHERE ID = @identity
			END

		END

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	THROW;
	----for tracking the which error getting
	UPDATE hubspotcontactscreatedorupdatedlogs
	SET ErrorMessages =  error_message()
	WHERE ID = @identity
	
	
END CATCH
END
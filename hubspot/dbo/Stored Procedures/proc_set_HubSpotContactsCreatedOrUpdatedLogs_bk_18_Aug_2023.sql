/*

EXEC proc_set_HubSpotContactsCreatedOrUpdatedLogs
    @HubSpotContactsIdentityKeyId = 2030
	,@HubSpotContactId = '16940694668'
	,@IsProcessed = 1
	,@IsSynced = 1
	,@ProcessedDate = '2023-08-17 08:13:34.487'
	,@SyncedDate = '2023-08-17 08:13:34.487'

*/
 
 
 
CREATE PROCEDURE [dbo].[proc_set_HubSpotContactsCreatedOrUpdatedLogs_bk_18_Aug_2023]
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

	BEGIN TRANSACTION

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

		----update HubSpotContacts 
		UPDATE HubSpotContacts
		SET [HubSpot Contact Id] = @HubSpotContactId
		,IsSynced                = @IsSynced
		,IsProcessed             = @IsProcessed
		,SyncedDate				 = @SyncedDate
		,ProcessedDate			 = @ProcessedDate
		WHERE Id                 = @HubSpotContactsIdentityKeyId

	COMMIT TRANSACTION
	   	  
END
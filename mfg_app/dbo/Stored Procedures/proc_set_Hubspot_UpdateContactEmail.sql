/*
 M2-4863 DB - HubSpot - Update Contacts module Email address upon change in MFG application.
*/
CREATE PROCEDURE [dbo].[proc_set_Hubspot_UpdateContactEmail]
(	 
	 @HubSpotContactId           VARCHAR(255) 
	,@mfgContactChangedEmail     VARCHAR(255)
)
AS
BEGIN
	 
	SET NOCOUNT ON
	 
	----DECLARE  @HubSpotContactId           VARCHAR(255) = 130251 	,@mfgContactUpdatedEmail     VARCHAR(255) = 'Nsupplieruat_123@yopmail.com'

	IF ( SELECT COUNT(1) FROM mp_contacts (NOLOCK) WHERE HubSpotContactId  = @HubSpotContactId ) > 0
	BEGIN
		  	BEGIN TRY
			BEGIN TRANSACTION

			--Update hubspot -> Email against @HubSpotContactId Id
			UPDATE c
			SET c.Email  = a.email 
			FROM  aspnetusers (NOLOCK) a  
			JOIN mp_contacts (NOLOCK) b ON a.id = b.user_id  
			JOIN DataSync_MarketplaceHubSpot.dbo.hubspotcontacts(NOLOCK) c ON c.[HubSpot Contact Id] = b.HubSpotContactId
				AND  a.email != c.Email  
			WHERE b.HubSpotContactId = @HubSpotContactId

			COMMIT TRANSACTION
			SELECT TransactionStatus  = 'Success'

			END TRY

			BEGIN CATCH
				ROLLBACK TRANSACTION
				SELECT TransactionStatus  = 'Failure'
			END CATCH

	END
	ELSE
	BEGIN
		SELECT NULL AS TransactionStatus 
	END


END


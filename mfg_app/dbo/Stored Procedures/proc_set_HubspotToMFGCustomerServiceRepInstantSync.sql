/*
  M2-5176 Hubspot - Downsync CS Rep - Instant - DB 

 EXEC [dbo].[proc_set_HubspotToMFGCustomerServiceRepInstantSync]
 @CompanyID = 1772113
 ,@HubSpotAccountId =15681976877
 ,@HubSpotCustomerServiceRepId =  52518328 -- 52518180  

*/
 CREATE PROCEDURE [dbo].[proc_set_HubspotToMFGCustomerServiceRepInstantSync]
 (
	@CompanyID INT = NULL
	,@HubSpotAccountId VARCHAR(100) = NULL 
    ,@HubSpotCustomerServiceRepId VARCHAR(100) = NULL --this field refer from hubspot -> mst_manager -> hubspot_user_id
 )
 AS
BEGIN
 SET NOCOUNT ON

	 DECLARE @CustomerServiceRepContactId  INT = NULL , @PreviousCustomerServiceRepContactId INT ,@Identity INT
	 	 
	 ---- for webhook log  entry tracking 
	 INSERT INTO HubSpotWebhookCustomerServiceRepExecutionLogs (CompanyID,HubSpotAccountId,HubSpotUserId,WebhookType)
	 VALUES (@CompanyID,@HubSpotAccountId,@HubSpotCustomerServiceRepId,'CustomerServiceRep')

	 SET @Identity = @@IDENTITY

	 ---Get the manager_id from hubspot database
	 SELECT @CustomerServiceRepContactId = manager_id FROM DataSync_MarketplaceHubSpot..mst_manager(NOLOCK) 
									WHERE hubspot_user_id = @HubSpotCustomerServiceRepId

	 ---Get the current CustomerServiceRepID from MFG database
	 SELECT @PreviousCustomerServiceRepContactId = assigned_customer_rep FROM mp_companies(NOLOCK) 
								    WHERE company_id= @CompanyID
	 
		   BEGIN TRY
				BEGIN TRANSACTION
				
					------ Update the assigned_customer_rep field to costomer service representative id from hubspot
		 			UPDATE mp_companies
					SET assigned_customer_rep  = @CustomerServiceRepContactId
					WHERE company_id= @CompanyID

					------ Update data into Hubspot DB
					UPDATE DataSync_MarketplaceHubSpot.dbo.hubspotcompanies
					SET [Customer Service Rep Id] = @CustomerServiceRepContactId
					WHERE [vision account id] = @CompanyID
					AND [SyncType] IS NULL

					---- Update this id from MFG CustomerServiceRepContactId  HubSpotWebhookCustomerServiceRepExecutionLogs -> PreviousCustomerServiceRepID
					UPDATE HubSpotWebhookCustomerServiceRepExecutionLogs
					SET PreviousCustomerServiceRepContactId = @PreviousCustomerServiceRepContactId
					WHERE LogID = @Identity
									 
			
				COMMIT TRANSACTION
			END TRY

			BEGIN CATCH
				ROLLBACK TRANSACTION
			END CATCH
	 

	  

 END

	   


/*
M2-4913 HubSpot - Instant Sync (Growth Package Field) - DB

*/
 CREATE PROCEDURE [dbo].[proc_set_HubspotToMFGCompanyGPInstantSync]
 (
	@CompanyID INT = NULL
	,@HubSpotAccountId VARCHAR(100)
    ,@IsEligibleForGrowthPackage BIT = NULL --- 0: False,   1: True
 )
 AS
 BEGIN
   
   ---- for webhook log  entry tracking 
   INSERT INTO HubSpotWebhookExecutionLogs (CompanyID,HubSpotAccountId,IsEligibleForGrowthPackage,WebhookType)
   VALUES (@CompanyID,@HubSpotAccountId,@IsEligibleForGrowthPackage,'GrowthPackageEligible')


	 IF NOT EXISTS 
	 (
		 SELECT TOP 1 b.id
		 FROM mp_gateway_subscription_customers (NOLOCK) a 
		 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
		 where a.company_id = @CompanyID --17700231
		 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
		 AND b.[status] = 'active'
		 ORDER BY b.id DESC
	 )
	 BEGIN
	 
		---- Update data into MFG
		UPDATE mp_companies
		SET IsEligibleForGrowthPackage = @IsEligibleForGrowthPackage
		, IsGrowthPackageTaken = 0
		WHERE company_id = @CompanyID

		---- Update data into Hubspot DB
		--UPDATE UAT_DataSync_MarketplaceHubSpot.dbo.hubspotcompanies
		UPDATE DataSync_MarketplaceHubSpot.dbo.hubspotcompanies
		SET IsEligibleForGrowthPackage = @IsEligibleForGrowthPackage
		WHERE [HubSpot Account Id]= @HubSpotAccountId
		AND [SyncType] = 2
 

	 END
	 

 END

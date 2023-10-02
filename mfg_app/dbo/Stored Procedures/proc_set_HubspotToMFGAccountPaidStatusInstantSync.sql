

/*
 M2-5051 HubSpot - Instant Sync (Account Paid Status Field) - DB

 EXEC [dbo].[proc_set_HubspotToMFGAccountPaidStatusInstantSync]
 @CompanyID = 1800921
 ,@HubSpotAccountId =15681976877
 ,@AccountPaidStatus = Basic  -- platinum ,Growth ,gold, Basic or free

*/
 CREATE PROCEDURE [dbo].[proc_set_HubspotToMFGAccountPaidStatusInstantSync]
 (
	@CompanyID INT = NULL
	,@HubSpotAccountId VARCHAR(100)
    ,@AccountPaidStatus VARCHAR(100) = NULL 
 )
 AS
 BEGIN
 --SET NOCOUNT ON

	-- declare @CompanyID INT = 1800921
	--,@HubSpotAccountId VARCHAR(100) = 15681976877
 --   ,@AccountPaidStatus VARCHAR(100) = 'Basic' -- platinum Growth gold Basic starter

	 
	  ---- for webhook log  entry tracking 
	  INSERT INTO HubSpotWebhookAccountPaidStatusExecutionLogs (CompanyID,HubSpotAccountId,AccountPaidStatus,WebhookType)
	  VALUES (@CompanyID,@HubSpotAccountId,@AccountPaidStatus,'AccountPaidStatus')

BEGIN TRY
	BEGIN TRANSACTION
 		 
	  IF  ISNULL(@AccountPaidStatus,'') IN ('free','Basic','')  
	  BEGIN
				--- if active subscription then do not delete and update
				IF NOT EXISTS 
						 (
							 SELECT TOP 1 b.id
							 FROM mp_gateway_subscription_customers (NOLOCK) a 
							 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
							 where a.company_id = @CompanyID --17700231
							 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
							 AND b.[status] IN ( 'active','trialing')
							 ORDER BY b.id DESC
						 )
				BEGIN
					DELETE FROM mp_registered_supplier  WHERE company_id = @CompanyID

					UPDATE mp_companies
					SET IsEligibleForGrowthPackage = 1
					,IsGrowthPackageTaken = 0 
					,IsStarterPackageTaken = 0
					WHERE company_id= @CompanyID
					---below condition added on 09-Aug-2023
					AND employee_count_range_id = 1
					AND Manufacturing_location_id <> 3
					
				END
	  END
	  ELSE
	  BEGIN
 				IF EXISTS ( SELECT company_id FROM mp_registered_supplier(NOLOCK) WHERE company_id = @CompanyID )
				BEGIN
			
					IF @AccountPaidStatus = 'Growth'
					BEGIN
						 --- if active subscription then do not update 
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
							UPDATE mp_companies
								SET IsEligibleForGrowthPackage = 1
								,IsGrowthPackageTaken = 0 
							WHERE company_id= @CompanyID
						END
					END 
					ELSE IF @AccountPaidStatus = 'Starter'
					BEGIN
						 --- if active subscription then do not update 
						 IF NOT EXISTS 
						 (
							 SELECT TOP 1 b.id
							 FROM mp_gateway_subscription_customers (NOLOCK) a 
							 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
							 where a.company_id = @CompanyID --17700231
							 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
							 AND b.[status] IN( 'active','trialing')
							 ORDER BY b.id DESC
						 )
						 BEGIN
							UPDATE mp_companies
								SET IsEligibleForGrowthPackage = 1
								,IsStarterPackageTaken = 0 
							WHERE company_id= @CompanyID
						END
						
					END
					ELSE
					BEGIN
						    --- if this user has active subscription than do not update
							IF NOT EXISTS 
									 (
										 SELECT TOP 1 b.id
										 FROM mp_gateway_subscription_customers (NOLOCK) a 
										 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
										 where a.company_id = @CompanyID  
										 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
										 AND b.[status] IN( 'active','trialing')
										 ORDER BY b.id DESC
									 )
							BEGIN
							 
								UPDATE mp_companies
									SET IsEligibleForGrowthPackage = NULL
									,IsGrowthPackageTaken = NULL 
									,IsStarterPackageTaken = NULL
								WHERE company_id= @CompanyID

								---- update mp_registered_supplier
								UPDATE mp_registered_supplier
								SET account_type = CASE WHEN @AccountPaidStatus = 'gold'     THEN 85
											WHEN @AccountPaidStatus = 'platinum' THEN 86
											WHEN @AccountPaidStatus = 'Growth'   THEN 84
											WHEN @AccountPaidStatus = 'Starter'  THEN 313
										END  
								,updated_on = GETUTCDATE()
 								WHERE company_id = @CompanyID
								
							END
							 
					END
					 
				END
				ELSE
				BEGIN
						---- insert mp_registered_supplier if not exists record
						INSERT INTO dbo.mp_registered_supplier (company_id,is_registered,created_on,account_type )
						VALUES (@CompanyID,1,GETUTCDATE(), CASE WHEN @AccountPaidStatus = 'gold'     THEN 85
																WHEN @AccountPaidStatus = 'platinum' THEN 86 
																WHEN @AccountPaidStatus = 'Growth'   THEN 84
																WHEN @AccountPaidStatus = 'Starter'  THEN 313
																END )
 
						IF @AccountPaidStatus = 'Growth'
						BEGIN
						     --- if active subscription then do not update 
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
								UPDATE mp_companies
									SET IsEligibleForGrowthPackage = 1
									,IsGrowthPackageTaken = 0 
								WHERE company_id= @CompanyID
							 END
						END 
						ELSE IF @AccountPaidStatus = 'Starter'
					    BEGIN
							 --- if active subscription then do not update 
							 IF NOT EXISTS 
							 (
								 SELECT TOP 1 b.id
								 FROM mp_gateway_subscription_customers (NOLOCK) a 
								 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
								 where a.company_id = @CompanyID --17700231
								 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
								 AND b.[status] IN( 'active','trialing')
								 ORDER BY b.id DESC
							 )
							 BEGIN
								UPDATE mp_companies
								SET IsEligibleForGrowthPackage = 1
								,IsStarterPackageTaken = 0 
								WHERE company_id= @CompanyID
							END
					    END
						ELSE
						BEGIN
							 --- if this user has active subscription than do not update
							IF NOT EXISTS 
									 (
										 SELECT TOP 1 b.id
										 FROM mp_gateway_subscription_customers (NOLOCK) a 
										 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
										 where a.company_id = @CompanyID  
										 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
										 AND b.[status] IN( 'active','trialing')
										 ORDER BY b.id DESC
									 )
								BEGIN
									UPDATE mp_companies
										SET IsEligibleForGrowthPackage = NULL
										,IsGrowthPackageTaken = NULL 
										,IsStarterPackageTaken = NULL 
									WHERE company_id= @CompanyID
								END
							 
						END

						/* M2-4945 HubSpot - Integrate Reshape User Registration API -DB 
							First time Account Paid Status from basic to Growth, Gold, Platinum then inserted such records into mpAccountPaidStatusDetails
						*/
						INSERT INTO mpAccountPaidStatusDetails (CompanyId,OldValue,NewValue,IsProcessed,IsSynced,SourceType)
						SELECT 
						  @CompanyID AS CompanyId
						, 83 AS OldValue
						, CASE WHEN @AccountPaidStatus = 'gold'      THEN 85
							  WHEN  @AccountPaidStatus  = 'platinum' THEN 86 
							  WHEN  @AccountPaidStatus  = 'Growth'   THEN 84
							  WHEN @AccountPaidStatus = 'Starter'    THEN 313
							  END AS NewValue
						, NULL AS IsProcessed
						, 0 AS IsSynced
						, 'AccountPaidStatusInstantSync' AS SourceType 
						/**/

				END
	
		END

	  ------ Update data into Hubspot DB
	  UPDATE DataSync_MarketplaceHubSpot.dbo.hubspotcompanies
	  SET [Account Paid Status] = CASE WHEN ISNULL(@AccountPaidStatus,'') = '' THEN 'Basic' ELSE @AccountPaidStatus END
	  WHERE [HubSpot Account Id]= @HubSpotAccountId
	  AND [SyncType] = 2

	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH

	  

 END

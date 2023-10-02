
CREATE PROCEDURE [dbo].[proc_set_DataSync_Update_HubSpotToMarketplace_CompanyContact]
 AS

 BEGIN
		SET NOCOUNT ON

		IF OBJECT_ID('tempdb..#tmp_HubSpotContactsDownSyncLogs') IS NOT NULL  
        DROP TABLE #tmp_HubSpotContactsDownSyncLogs

		IF OBJECT_ID('tempdb..#HubSpotCompaniesDownSyncLogs') IS NOT NULL  
        DROP TABLE #HubSpotCompaniesDownSyncLogs

		IF OBJECT_ID('tempdb..#HubSpotCompanies_mp_registered_supplier_insert') IS NOT NULL  
        DROP TABLE #HubSpotCompanies_mp_registered_supplier_insert

        DECLARE @TodaysDate Date = GETUTCDATE()--- M2-4691  
		 
	IF OBJECT_ID('tempdb..#tmp_GetSubscriptionCompanies') IS NOT NULL  
        DROP TABLE #tmp_GetSubscriptionCompanies

		CREATE TABLE #tmp_GetSubscriptionCompanies
		(
			[Id] INT    IDENTITY (1,1)
			,[CompanyId]  INT NULL
			,[SubscriptionEndDate] DATE
			,[SubscriptionEndDateAfter7Days] DATE
			,[SubscriptionStatus] VARCHAR(25)
     	)

		--- if SyncType = 2 records are found then go for further process
		IF (SELECT COUNT(1) FROM DataSync_MarketplaceHubSpot.dbo.HubSpotContacts (NOLOCK) 
			WHERE SyncType = 2 and ISNULL(issynced,0) = 0 
			and ISNULL(isprocessed,0) = 0 
		) > 0
		BEGIN
		PRINT 'RECORDS FOUND TO UPDATE CONTACT DETAILS'
		/*
			Contact Module : Buyer and Supplier
		*/

		CREATE TABLE #tmp_HubSpotContactsDownSyncLogs    
		(   [id] INT IDENTITY (1,1)
			,[Vision Contact Id]  INT null
			,[First Name] VARCHAR (255) null
			,[Last Name] VARCHAR (255) null
			,[Email Opt Out] BIT null
			,[HubSpot Identity] INT null
			,[HubSpot Contact Id] VARCHAR (255) null ----M2-4863
		) 

		---- Inserted records inserted into temporary table for further processing
		INSERT INTO #tmp_HubSpotContactsDownSyncLogs  
		(
			    [Vision Contact Id]
			  , [First Name]
			  , [Last Name]
			  , [Email Opt Out]
			  , [HubSpot Identity] ---- this is pk field of HubSpotContacts table
			  , [HubSpot Contact Id]  ----M2-4863
		)
		---- Buyer details 
		SELECT 
			[Vision Buyer Id]
			, [buyer first name] 
			, [buyer last name]
			, CASE WHEN [Unsubscribed from all email] = 1 THEN 0 ELSE 1 END AS  [Unsubscribed from all email]
			, [Id]
			, [HubSpot Contact Id]
		FROM  DataSync_MarketplaceHubSpot.dbo.HubSpotContacts(NOLOCK) a 
		WHERE a.SyncType = 2 and ISNULL(a.IsSynced,0)=0 
		and ISNULL(a.isprocessed,0) = 0 
		UNION ALL
		---- Supplier details 
			SELECT 
			[Vision Supplier Id]
			, [First Name]
			, [Last Name]
			--, [Unsubscribed from all email] 
			, CASE WHEN [Unsubscribed from all email] = 1 THEN 0 ELSE 1 END AS  [Unsubscribed from all email]
			, [Id]
			, [HubSpot Contact Id]
			FROM  DataSync_MarketplaceHubSpot.dbo.HubSpotContacts(NOLOCK) a 
		WHERE a.SyncType = 2  and ISNULL(a.IsSynced,0)=0 
		and ISNULL(a.isprocessed,0) = 0 
		--and ISNULL(a.ProcessedDate,0)=0

		
		---- Hubspot log table insertion
		INSERT INTO DataSync_MarketplaceHubSpot.dbo.HubSpotContactsDownSyncLogs  
		(
			    [Vision Contact Id]
			  , [First Name]
			  , [Last Name]
			  , [Email Opt Out]
		)
		  SELECT [Vision Contact Id]
			  , [First Name]
			  , [Last Name]
			  , [Email Opt Out]
			  FROM #tmp_HubSpotContactsDownSyncLogs

		----- update following fields 
		---- first name  
		UPDATE b
		SET b.first_name = a.[First Name]
		FROM #tmp_HubSpotContactsDownSyncLogs(NOLOCK) a 
		JOIN dbo.mp_contacts(NOLOCK) b ON a.[Vision Contact Id]  = b.contact_id
		WHERE a.[First Name] != ISNULL(b.first_name,'')
		AND a.[First Name] IS NOT NULL 
 
		---- last name  
		UPDATE b
		SET b.last_name = a.[Last Name]
		FROM #tmp_HubSpotContactsDownSyncLogs(NOLOCK) a 
		JOIN dbo.mp_contacts(NOLOCK) b on a.[Vision Contact Id]  = b.contact_id
		WHERE a.[Last Name] != b.last_name
		AND a.[Last Name] IS NOT NULL

 		---- Email_Opt_Out
		UPDATE b
		SET b.is_notify_by_email =  a.[Email Opt Out]
		FROM #tmp_HubSpotContactsDownSyncLogs(NOLOCK) a 
		JOIN dbo.mp_contacts(NOLOCK) b on a.[Vision Contact Id]  = b.contact_id
		WHERE a.[Email Opt Out] != b.is_notify_by_email
		AND a.[Email Opt Out] IS NOT NULL

		----  M2-4863 Update HubSpotContactId from HubSpot DB to MFG DB
		UPDATE b
		SET b.HubSpotContactId =  a.[HubSpot Contact Id]
		FROM #tmp_HubSpotContactsDownSyncLogs(NOLOCK) a 
		JOIN dbo.mp_contacts(NOLOCK) b on a.[Vision Contact Id]  = b.contact_id
		WHERE  a.[HubSpot Contact Id] IS NOT NULL 
				AND b.HubSpotContactId IS NULL
		 		
		----finally update fields in hubspot -> HubSpotContacts
		UPDATE a
		set a.IsSynced = 1
		, a.SyncedDate = GETUTCDATE()
        , a.IsProcessed =  1
		, a.ProcessedDate = GETUTCDATE()
		from 
		DataSync_MarketplaceHubSpot.dbo.HubSpotContacts (NOLOCK) a 
		join #tmp_HubSpotContactsDownSyncLogs b ON a.id = b.[HubSpot Identity]
		WHERE a.SyncType = 2 
		AND ISNULL(a.issynced,0) = 0
		AND  ISNULL(a.IsProcessed,0)=0
		--AND  a.ProcessedDate IS NULL
			   

END
ELSE
BEGIN
PRINT 'NO RECORDS FOUND TO UPDATE CONTACT DETAILS'
END
		/* Contact module
		   M2-4983
		*/
		  
		   ---- Buyer details 
		    UPDATE  b
			SET b.HubSpotContactId = a.[HubSpot Contact Id]
			FROM  DataSync_MarketplaceHubSpot.dbo.HubSpotContacts(NOLOCK) a 
			JOIN mp_contacts(NOLOCK) b on  a.[Vision Buyer Id] = b.contact_id AND b.is_buyer = 1
			WHERE a.[Vision Buyer Id] IS NOT NULL 
			AND a.[HubSpot Contact Id] IS NOT NULL
			AND b.HubSpotContactId IS NULL 
		
			---- Supplier details 
			UPDATE b
			SET b.HubSpotContactId = a.[HubSpot Contact Id]
			FROM  DataSync_MarketplaceHubSpot.dbo.HubSpotContacts(NOLOCK) a 
			JOIN mp_contacts(NOLOCK) b on  a.[Vision Supplier Id] = b.contact_id AND b.is_buyer = 0
			WHERE a.[Vision Supplier Id] IS NOT NULL 
			AND a.[HubSpot Contact Id] IS NOT NULL
			AND b.HubSpotContactId IS NULL 
		

		/* */
		/*
			Account/Company Module
		*/

		CREATE TABLE #HubSpotCompaniesDownSyncLogs
		(
			[Id] INT    IDENTITY (1,1)
			,[Vision Account Id]  INT NULL
			,[Hide Directory Profile] BIT NULL
			,[Manufacturing Location] VARCHAR (100) NULL
			,[Company Owner Id] INT NULL
			,[Account Paid Status] VARCHAR (100) NULL
			,[Account Type] int NULL
			,[HubSpot Identity] INT NULL
			,[IsEligibleForGrowthPackage]  BIT NULL
		)


		IF (SELECT COUNT(1) FROM DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies (NOLOCK) 
			WHERE SyncType = 2 and ISNULL(issynced,0) = 0 and ISNULL(isprocessed,0) = 0 
		) > 0
		BEGIN
		PRINT 'RECORDS FOUND TO UPDATE COMPANY DETAILS'
		INSERT INTO #HubSpotCompaniesDownSyncLogs 
		(
			[Vision Account Id]
			,[Hide Directory Profile] 
			,[Manufacturing Location]
			,[Company Owner Id]
			,[Account Paid Status] 
			,[Account Type]
			,[HubSpot Identity]  ---- this is pk field of HubSpotContacts table
			,[IsEligibleForGrowthPackage]
		)
			SELECT 
				[Vision Account Id]
				, [Hide Directory Profile] 
				, [Manufacturing Location] 
				, [Company Owner Id] 
				, [Account Paid Status]
				, CASE WHEN [Account Paid Status]  =  'Growth'   THEN 84
					   WHEN  [Account Paid Status] =  'Gold'     THEN 85
					   WHEN  [Account Paid Status] =  'Platinum' THEN 86
					   WHEN  [Account Paid Status] =  'Starter'  THEN 313 ---Added with M2-5133
					   ELSE 0 ---- this is "free" so such records we are not inserted in MFG- > mp_registered_supplier table and we don't have FREE status in MFG
				  END as [Account Type]
				, [Id]
                                , [IsEligibleForGrowthPackage]
			FROM  DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies(NOLOCK) a 
			WHERE a.SyncType = 2 and ISNULL(a.IsSynced,0) = 0 and ISNULL(a.IsProcessed,0)=0 --ISNULL(a.ProcessedDate,0)=0

			/* Before delete records from mp_registered_supplier, we need to check this user [Account Type] = 0 from hubspot
			and account_type = 84 in mp_registered_supplier table then need to perform update in mp_companies 
			to reset the fields IsEligibleForGrowthPackage = 1 and IsGrowthPackageTaken = 0 for this user again take
			growth package 
			*/
			UPDATE c  
			SET c.IsEligibleForGrowthPackage = 1
			, c.IsGrowthPackageTaken = 0 
			from #HubSpotCompaniesDownSyncLogs a
			JOIN mp_registered_supplier (NOLOCK) b ON a.[Vision Account Id] = b.company_id
			JOIN mp_companies (NOLOCK) c ON c.company_id = b.company_id
			WHERE a.[Account Type] = 0 AND b.account_type = 84
			/**/
						 
			--- if hubspot any account set account_type = free then this record deleted from mp_registered_supplier if exists
			DELETE FROM mp_registered_supplier
			WHERE company_id IN 
			(
				SELECT [Vision Account Id] -- INTO #HubSpotCompanies_mp_registered_supplier_insert 
				FROM #HubSpotCompaniesDownSyncLogs   
				WHERE  [Account Type] = 0 --- to skip free records inserted into mfg table
				/* Nov 09 2022 skipping growth package companies because of downsync issue of 10k which is causing companies paid status  */
				--AND   [Vision Account Id] NOT IN  (SELECT DISTINCT company_id FROM mp_gateway_subscription_customers WHERE gateway_id = 310)
				/**/
				AND EXISTS 
				(
					SELECT company_id FROM mp_registered_supplier(NOLOCK) 
					WHERE mp_registered_supplier.company_id = #HubSpotCompaniesDownSyncLogs.[Vision Account Id]
				)
			)
			
			-----insert records into temptable for mp_registered_supplier which are not existed into mp_registered_supplier
			SELECT * INTO #HubSpotCompanies_mp_registered_supplier_insert 
			FROM #HubSpotCompaniesDownSyncLogs   
			WHERE NOT EXISTS (select company_id from mp_registered_supplier(nolock) 
				WHERE mp_registered_supplier.company_id = #HubSpotCompaniesDownSyncLogs.[Vision Account Id])
				AND [Account Type] != 0 --- to skip free records inserted into mfg table

			/* M2-4945 HubSpot - Integrate Reshape User Registration API -DB 
					First time Account Paid Status from basic to Growth, Gold, Platinum then inserted such records into mpAccountPaidStatusDetails
			*/
			INSERT INTO mpAccountPaidStatusDetails (CompanyId,OldValue,NewValue,IsProcessed,IsSynced,SourceType)
			SELECT [Vision Account Id], 83 AS OldValue, [account type] AS NewValue, NULL AS IsProcessed,0 AS IsSynced, 'Job-UpdateSync' AS SourceType 
			FROM #HubSpotCompaniesDownSyncLogs a
			WHERE NOT EXISTS ( select CompanyId from  mpAccountPaidStatusDetails b (NOLOCK) WHERE b.CompanyId = a.[Vision Account Id] )
			AND [account type] not in (84,0) --- means growth/Basic -- TBD this condition added becoz GP entry should be insert after GP purchased via SP proc_set_company_subscription
			/**/

			---- Hubspot log table insertion
		
			INSERT INTO DataSync_MarketplaceHubSpot.dbo.HubSpotCompaniesDownSyncLogs  
			(
			    [Vision Account Id]
			  	, [Hide Directory Profile] 
				, [Manufacturing Location] 
				, [Company Owner Id] 
				, [Account Paid Status]
				, [IsEligibleForGrowthPackage]
			)
			SELECT 
				[Vision Account Id]
				, [Hide Directory Profile] 
				, [Manufacturing Location] 
				, [Company Owner Id] 
				, [Account Paid Status]
				, [IsEligibleForGrowthPackage]
			FROM #HubSpotCompaniesDownSyncLogs 

			----- update following fields 
			---- is_hide_directory_profile
			UPDATE b
			SET b.is_hide_directory_profile =  a.[Hide Directory Profile]
			FROM #HubSpotCompaniesDownSyncLogs(NOLOCK) a 
			JOIN dbo.mp_companies(NOLOCK) b ON a.[Vision Account Id]  = b.company_id
			WHERE a.[Hide Directory Profile] != ISNULL(b.is_hide_directory_profile,'')
			AND a.[Hide Directory Profile]  IS NOT NULL

			---- manufacturing_location_id
			UPDATE b
			SET b.manufacturing_location_id =  a.[Manufacturing Location]
			FROM #HubSpotCompaniesDownSyncLogs(NOLOCK) a 
			JOIN dbo.mp_companies(NOLOCK) b ON a.[Vision Account Id]  = b.company_id
			WHERE a.[Manufacturing Location] != ISNULL(b.manufacturing_location_id,'')
			AND a.[Manufacturing Location] IS NOT NULL

			---- assigned_sourcingadvisor
			UPDATE b
			SET b.assigned_sourcingadvisor =  a.[Company Owner Id] 
			FROM #HubSpotCompaniesDownSyncLogs(NOLOCK) a 
			JOIN dbo.mp_companies(NOLOCK) b ON a.[Vision Account Id]  = b.company_id
			WHERE a.[Company Owner Id]  != ISNULL(b.assigned_sourcingadvisor,'')
			AND a.[Company Owner Id] IS NOT NULL

			/* M2-4983 */
			--- HubSpotCompanyId 
			UPDATE   b
			SET b.HubSpotCompanyId = a.[HubSpot Account Id] 
			FROM DataSync_MarketplaceHubSpot..hubspotcompanies (NOLOCK) a 
			JOIN dbo.mp_companies(NOLOCK) b ON a.[Vision Account Id]  = b.company_id
			WHERE b.HubSpotCompanyId IS NULL AND a.[HubSpot Account Id] IS NOT NULL
			----Commented on 07-Sep-2023 because all companies should be update HubSpotCompanyId field in mfg app
			----AND a.SyncType = 2 and ISNULL(a.IsSynced,0) = 0 and ISNULL(a.IsProcessed,0)=0
			/* */
			---- AccountPaidStatus
			IF (SELECT COUNT(1) FROM #HubSpotCompanies_mp_registered_supplier_insert ) > 0
			BEGIN
				------ if records not existsed then  inserted into mp_registered_supplier
				insert into dbo.mp_registered_supplier (company_id,is_registered,created_on,account_type )
				select [Vision Account Id],1 [is_registered], getutcdate() created_on ,[account type]
				from #HubSpotCompanies_mp_registered_supplier_insert 
				
				/* M2-4945 HubSpot - Integrate Reshape User Registration API -DB 
					First time Account Paid Status from basic to Growth, Gold, Platinum then inserted such records into mpAccountPaidStatusDetails
				*/
				--INSERT INTO mpAccountPaidStatusDetails (CompanyId,OldValue,NewValue,IsProcessed,IsSynced,SourceType)
				--SELECT [Vision Account Id], 83 AS OldValue, [account type] AS NewValue, NULL AS IsProcessed,0 AS IsSynced, 'Job-UpdateSync' AS SourceType 
				--FROM #HubSpotCompanies_mp_registered_supplier_insert a
				--WHERE NOT EXISTS ( select CompanyId from  mpAccountPaidStatusDetails b (NOLOCK) WHERE b.CompanyId = a.[Vision Account Id] )
				--AND [account type] != 84 --- means growth -- TBD this condition added becoz GP entry should be insert after GP purchased via SP proc_set_company_subscription
				/* */
			END
					
				UPDATE c
				SET c.account_type =  a.[Account Type] , c.updated_on = getutcdate() , c.account_type_source = NULL
				FROM #HubSpotCompaniesDownSyncLogs(NOLOCK) a 
				JOIN dbo.mp_companies(NOLOCK) b ON a.[Vision Account Id]  = b.company_id
				JOIN dbo.mp_registered_supplier(NOLOCK) c ON b.company_id  = c.company_id
				WHERE a.[Account Type]  != c.account_type
				AND a.[Account Type] != 0 ---- this is "free" so such records we are not inserted in MFG- > mp_registered_supplier table and we don't have FREE status in MFG
			    AND a.[Vision Account Id] NOT IN (SELECT [Vision Account Id] FROM #HubSpotCompanies_mp_registered_supplier_insert )
		   /* M2-4691 Code changes  
			 1. If any user has active growth package subscription and from hubspot someone turn off the flag then in MFG no action performed. 

			 2. If any user has expired/cancel growth package subscription and from hubspot someone turn off the flag then 
			    in MFG, following impact in application.
			 1. Need to delete record from registered supplier ? (so this user become basic)
			 2. Need to set flag to 0 ( IsEligibleForGrowthPackage and IsGrowthPackageTaken) ?  
			 3. adding update in directory datasync ( for community update)
			 4. can we delete existing company subscription quoting capabilities data if payment failed ?  
		   */
			
			/* 1. If user is set for growth package.  */
			---- [IsEligibleForGrowthPackage] = 0 OR 1
			UPDATE b
			SET b.IsEligibleForGrowthPackage =  a.[IsEligibleForGrowthPackage]
			FROM #HubSpotCompaniesDownSyncLogs(NOLOCK) a 
			JOIN dbo.mp_companies(NOLOCK) b ON a.[Vision Account Id]  = b.company_id
			WHERE a.[IsEligibleForGrowthPackage]  IS NOT NULL
			AND b.company_id NOT IN ( SELECT company_id from mp_gateway_subscription_customers (NOLOCK) WHERE gateway_id = 310)
			
		    --Getting data from subscription table against company id
			INSERT INTO #tmp_GetSubscriptionCompanies ( [CompanyId],[SubscriptionEndDate],[SubscriptionStatus])
			SELECT subscription.company_id ,subscription.subscription_end ,b.[status]
			FROM (
					SELECT  a.company_id, MAX(b.subscription_end) AS subscription_end ,  MAX(b.created) AS created
					FROM  mp_gateway_subscription_customers (NOLOCK) a
					JOIN mp_gateway_subscriptions (NOLOCK) b on a.id = b.customer_id --AND status = 'past_due'
					JOIN #HubSpotCompaniesDownSyncLogs c on c.[Vision Account Id]  = a.company_id  
		 			WHERE a.gateway_id = 310 
					GROUP BY a.company_id
			) subscription 
			JOIN mp_gateway_subscription_customers (NOLOCK) a on a.company_id =  subscription.company_id
			JOIN mp_gateway_subscriptions (NOLOCK) b on a.id = b.customer_id and subscription.subscription_end = b.subscription_end
			  AND  b.created = subscription.created
			WHERE a.gateway_id = 310

			-- UPDATE subscription end + 30 days
			UPDATE #tmp_GetSubscriptionCompanies
			SET [SubscriptionEndDateAfter7Days] = CAST(DATEADD(dd,30,[SubscriptionEndDate]) AS DATE)
			FROM #tmp_GetSubscriptionCompanies

			/*delete record from registered supplier */
			DELETE FROM mp_registered_supplier 
			WHERE company_id IN 
			(
				SELECT  CompanyId FROM #tmp_GetSubscriptionCompanies a
				JOIN #HubSpotCompaniesDownSyncLogs b ON a.CompanyId = b.[Vision Account Id]
				WHERE b.IsEligibleForGrowthPackage = 0
				AND [SubscriptionEndDateAfter7Days] <  @TodaysDate
			)
			
			-- adding manufacturer in directory datasync
			INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
			SELECT a.company_id ,'paid_status' ,GETUTCDATE() 
			FROM mp_companies (NOLOCK) a 
			JOIN #tmp_GetSubscriptionCompanies b ON a.company_id = b.CompanyId
			JOIN #HubSpotCompaniesDownSyncLogs c ON c.[Vision Account Id] = a.company_id
			WHERE  c.IsEligibleForGrowthPackage = 0
			AND SubscriptionEndDateAfter7Days <  @TodaysDate
			
			 /* set flag to 0 for IsGrowthPackageTaken */
			UPDATE mp_companies 
			SET IsGrowthPackageTaken = 0
			FROM mp_companies (NOLOCK) a 
			JOIN #tmp_GetSubscriptionCompanies b ON a.company_id = b.CompanyId
			JOIN #HubSpotCompaniesDownSyncLogs c ON c.[Vision Account Id] = a.company_id
			WHERE c.IsEligibleForGrowthPackage = 0
			AND SubscriptionEndDateAfter7Days <  @TodaysDate
			
			/* delete existing company subscription quoting */
			DELETE FROM mp_gateway_subscription_company_processes 
			WHERE company_id IN 
			(
				SELECT  CompanyId FROM #tmp_GetSubscriptionCompanies a
				JOIN #HubSpotCompaniesDownSyncLogs b ON b.[Vision Account Id] = a.companyid
				WHERE b.IsEligibleForGrowthPackage = 0
				AND SubscriptionEndDateAfter7Days <  @TodaysDate
			) 
			
			/*
			 select * from #tmp_GetSubscriptionCompanies
			 select * from #HubSpotCompaniesDownSyncLogs
			*/
			----finally update fields in hubspot -> HubSpotCompanies
			UPDATE a
			set a.IsSynced = 1
			, a.SyncedDate = GETUTCDATE()
			, a.IsProcessed =  1
			, a.ProcessedDate = GETUTCDATE()
			FROM 
			DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies(NOLOCK) a 
			join #HubSpotCompaniesDownSyncLogs b ON a.id = b.[HubSpot Identity]
			WHERE a.SyncType = 2 
			AND ISNULL(a.issynced,0) = 0
			AND ISNULL( a.IsProcessed ,0 )= 0 
			--AND  a.ProcessedDate IS NULL

		END
		ELSE
		BEGIN
		PRINT 'NO RECORDS FOUND TO UPDATE COMPANY DETAILS'
		END
END

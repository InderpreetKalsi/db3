

--SELECT * FROM mpGrowthPackageUnlockRFQsInfo  WHERE CompanyID=1854421

--UPDATE mpGrowthPackageUnlockRFQsInfo SET IsDeleted = 1  WHERE CompanyID=1854421 
---- exec [proc_get_GrowthPackageManufacturerFlag] @CompanyID=1854421
CREATE PROCEDURE [dbo].[proc_get_GrowthPackageManufacturerFlag]  
(@CompanyId int )  
AS  

BEGIN  
 SET NOCOUNT ON   

 --  M2-4616 : Hubspot - Add the Growth Package Flag to the down sync
	
	DECLARE @IsEligibleForGrowthPackage INT ,@IsGrowthPackageTaken INT  ,@UnlockRfqCount INT , @TotalUnlockRfqCount INT , @NoOfDaysLeft INT 
	,@IsStarterPackageTaken BIT , @IsStarterFreeTrialTaken BIT,  @FreeTrialSubscriptionEndDate DATETIME 

	DECLARE @AccountType INT = (SELECT account_type FROM  [mp_registered_supplier] (NOLOCK)  WHERE company_id = @CompanyId )

	DECLARE @SubscriptionStatus VARCHAR(25) , @RunningSubscriptionId INT

	SELECT 
		@IsEligibleForGrowthPackage = IsEligibleForGrowthPackage
		,@IsGrowthPackageTaken      = IsGrowthPackageTaken
		,@IsStarterPackageTaken     = IsStarterPackageTaken
		,@IsStarterFreeTrialTaken   = IsStarterFreeTrialTaken
	FROM mp_companies (NOLOCK) 
	WHERE Company_Id = @CompanyId
	 
	-- To show unlock option in left panel  
	SELECT @TotalUnlockRfqCount = COUNT(DISTINCT Rfq_Id) FROM mpGrowthPackageUnlockRFQsInfo (NOLOCK) 
	WHERE CompanyId = @CompanyId 
	-- AND IsDeleted = 0 
	AND IsDeleted IN (0,1) -- to show unlock tab in left menu
	
	 --- below code commented with M2-5221
	 ---- Getting status and latest running id against company id
	 --SELECT  TOP 1  @SubscriptionStatus =   b.status , @RunningSubscriptionId = b.id 
		--FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		--JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
		--WHERE a.gateway_id = 310 
		--AND a.company_id = @CompanyId
		----and status = 'active'
		--ORDER BY b.ID DESC

	   ------ Updated code with M2-5221
		;with cte as 
		(
			SELECT   MAX(b.subscription_start)  subscription_start 
			, MAX(b.subscription_end) subscription_end
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			WHERE a.gateway_id = 310 
			AND a.company_id = @CompanyId
		)  
			SELECT  TOP 1     @SubscriptionStatus =   b.status ,   @RunningSubscriptionId = b.id 
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			JOIN cte on cte.subscription_start = b.subscription_start and cte.subscription_end = b.subscription_end
			WHERE a.gateway_id = 310 
			AND a.company_id = @CompanyId
			ORDER BY b.ID DESC
 
	IF @SubscriptionStatus IS NULL
	   BEGIN
	
			SET @UnlockRfqCount =
			(
					SELECT COUNT(DISTINCT c.rfq_id)
					FROM mpGrowthPackageUnlockRFQsInfo (NOLOCK) c 
					WHERE c.IsDeleted = 0 AND companyid = @CompanyId
						 
			)

	    END
	ELSE IF @SubscriptionStatus = 'active'
		BEGIN
		
		SET @UnlockRfqCount =
			(
					SELECT COUNT(DISTINCT c.rfq_id)
					FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
					JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
						a.id = b.customer_id 
						AND a.company_id = @CompanyId
					JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
					/* Slack issue : restored used RFQs -> IsDeleted = 1 */  
					AND c.IsDeleted = 0
					WHERE 
					    b.id = @RunningSubscriptionId
						AND c.UnlockDate  >= b.subscription_start
						AND c.UnlockDate <= b.subscription_end
			)
				 
				SET @NoOfDaysLeft =  
				(
					SELECT NoOfDaysLeft FROM
					(
						SELECT 
							DATEDIFF(DAY,GETUTCDATE(), b.subscription_end) NoOfDaysLeft  
							, ROW_NUMBER() OVER(PARTITION BY a.company_id ORDER BY a.company_id , b.Id DESC) Rn
						FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
						JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 					
							a.id = b.customer_id 
							AND a.company_id = @CompanyId
					) a 
					WHERE Rn  = 1
				)

		END
	ELSE IF @SubscriptionStatus = 'canceled'
		BEGIN
		 
				SET @UnlockRfqCount =
					(
							SELECT COUNT(DISTINCT c.rfq_id)
							FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
							JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
								a.id = b.customer_id 
								AND a.company_id = @CompanyId
							JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
							/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
							AND c.IsDeleted = 0
							WHERE b.id = @RunningSubscriptionId
							   AND	c.UnlockDate  >= b.subscription_start
							   AND CAST(c.UnlockDate AS DATE) <=  CAST(DATEADD(dd,30, b.subscription_end) AS DATE)
					) 

				SET @NoOfDaysLeft =  0  --- here set the value 0 because subscription cancel and no active subscription 

		END	 
	ELSE
		BEGIN

				SET @UnlockRfqCount =
					(
							SELECT COUNT(DISTINCT c.rfq_id)
							FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
							JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
								a.id = b.customer_id 
								AND a.company_id = @CompanyId
							JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
							/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
							AND c.IsDeleted = 0
							WHERE b.id = @RunningSubscriptionId
							   AND	c.UnlockDate  >= b.subscription_start
							   AND CAST(c.UnlockDate AS DATE) <=  CAST(DATEADD(dd,30, b.subscription_end) AS DATE)
					) 

					SET @NoOfDaysLeft =  
						(
							SELECT NoOfDaysLeft FROM
							(
								SELECT 
									DATEDIFF(DAY,GETUTCDATE(),CAST(DATEADD(dd,30, b.subscription_end) AS DATE) ) NoOfDaysLeft  
									, ROW_NUMBER() OVER(PARTITION BY a.company_id ORDER BY a.company_id , b.Id DESC) Rn
								FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
								JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
									a.id = b.customer_id 
									AND a.company_id = @CompanyId
							) a 
							WHERE Rn  = 1
						)

		END 
		
		---- First record information of company when starter package purchased
		IF @SubscriptionStatus = 'trialing'
		BEGIN
				SELECT  TOP 1  @FreeTrialSubscriptionEndDate =  subscription_end
				FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
				WHERE a.gateway_id = 310 
				AND a.company_id = @CompanyId
				AND b.status = 'trialing'
				ORDER BY b.ID  
		END


  	SELECT  
		ISNULL(@IsEligibleForGrowthPackage,0) AS IsEligibleForGrowthPackage
		, ISNULL(@IsGrowthPackageTaken,0)   AS IsGrowthPackageTaken  
		, ISNULL((CASE WHEN @SubscriptionStatus IS NULL THEN 0 WHEN @UnlockRfqCount = 0 THEN 3 ELSE 3-@UnlockRfqCount END ),0)  AS UnlockRfqCount
		, (CASE WHEN @NoOfDaysLeft > 0 THEN @NoOfDaysLeft ELSE 0 END) NoOfDaysLeft
		, ISNULL(@IsStarterPackageTaken,0) AS IsStarterPackageTaken
		, ISNULL(@IsStarterFreeTrialTaken,0) AS IsStarterFreeTrialTaken
		, @FreeTrialSubscriptionEndDate AS FreeTrialSubscriptionEndDate
		, ISNULL(@TotalUnlockRfqCount,0)   AS TotalUnlockRfqCount  
   
END







/*


-- basic / standard / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194969 , @SupplierID = 1373306
-- basic / standard / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194969 , @SupplierID = 1373306
-- basic / custom / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194969 , @SupplierID = 1373306
-- basic / custom / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194969 , @SupplierID = 1373306


-- starter / standard / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194929 , @SupplierID = 1373278
-- starter / standard / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194926 , @SupplierID = 1373278
-- starter / custom / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194927 , @SupplierID = 1373278
-- starter / custom / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194928 , @SupplierID = 1373278


-- growth / standard / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194929 , @SupplierID = 1373279
-- growth / standard / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194926 , @SupplierID = 1373279
-- growth / custom / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194927 , @SupplierID = 1373279
-- growth / custom / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194928 , @SupplierID = 1373279


-- gold / standard / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194929 , @SupplierID = 1373280
-- gold / standard / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194926 , @SupplierID = 1373280
-- gold / custom / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194927 , @SupplierID = 1373280
-- gold / custom / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194928 , @SupplierID = 1373280



-- platinum / standard / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194929 , @SupplierID = 1373281
-- platinum / standard / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194926 , @SupplierID = 1373281
-- platinum / custom / nda level 1  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194927 , @SupplierID = 1373281
-- platinum / custom / nda level 2  
EXEC [proc_get_Rfq_NDALevel_&_File_Access_Info] @RfqId = 1194928 , @SupplierID = 1373281

*/

CREATE PROCEDURE [dbo].[proc_get_Rfq_NDALevel_&_File_Access_Info]
(
	@RfqId INT
	,@SupplierId INT
)
AS
BEGIN

	-- M2-5257 NDA - Supplier can see the part files without buyer level approval if the page didn’t refresh.
	DECLARE @RfqAccessInfo	VARCHAR(8000)
	DECLARE @CompanyId		INT
	DECLARE @AccountType	INT = 83
	DECLARE @NDALevel		INT
	DECLARE @IsRfqUnlocked	INT
	DECLARE @UnlockedRfqsCount INT = 0
	DECLARE @SubscriptionStatus VARCHAR(25), @RunningSubscriptionId INT
	DECLARE @ActionForGrowthPackage  VARCHAR(25)
	DECLARE @MatchedPartCount INT = 0
	DECLARE @IsNDAAcceptedBySupplier	INT 
	DECLARE @IsNDAApprovedByBuyer		INT 
	DECLARE @IsSubscriptionSupplier		BIT = 0
	DECLARE @IsCustomNDA		INT = 0


	-- fetch companyid based on contact id
	SET @CompanyId = (SELECT company_id FROM mp_contacts (NOLOCK) WHERE contact_id = @SupplierId)
	
	-- fetch company account type based on company id
	SET @AccountType = (SELECT account_type FROM mp_registered_supplier (NOLOCK) WHERE company_id = @CompanyId)
	SET @AccountType = ISNULL(@AccountType,83)
	
	-- fetch nda level based on rfq id
	SET @NDALevel = (SELECT pref_NDA_Type FROM mp_rfq (NOLOCK) WHERE rfq_id = @RfqId)
	
	-- fetch rfq unlock info
	SET @IsRfqUnlocked = (SELECT Rfq_Id  FROM mpGrowthPackageUnlockRFQsInfo (NOLOCK) WHERE CompanyId = 	@CompanyId	AND IsDeleted = 0 AND Rfq_Id = @RfqId )

	-- fetch supplier has quoting capability
	SET @IsSubscriptionSupplier =
	(
		CASE	
			WHEN (SELECT COUNT(1) FROM mp_gateway_subscription_company_processes (NOLOCK)  WHERE  company_id =  @CompanyId AND is_active = 1)> 0 THEN CAST('true' AS BIT) 
			ELSE CAST('false' AS BIT) 
		END 
	)

	-- identity standard or custum nda
	SET @IsCustomNDA = (SELECT COUNT(1) FROM mp_rfq_accepted_nda (NOLOCK) WHERE rfq_id = @RfqId  AND nda_content = '' AND status_id = 2)

	-- fetching nda accepted and approved info 
	SELECT 
		@IsNDAAcceptedBySupplier = is_prefered_nda_type_accepted 
		, @IsNDAApprovedByBuyer = isapprove_by_buyer  
	FROM [dbo].[mp_rfq_supplier_nda_accepted] (NOLOCK) WHERE rfq_id = @RfqId AND contact_id = @SupplierId


	-- for basic users hide NDA 1 Modal / NDA2 Modal  and disable file download
	IF @AccountType = 83
	BEGIN
		
		SET @RfqAccessInfo =
			(
				SELECT 
					CAST('false' AS BIT)  AS showNDA1Modal 
					,CAST('false' AS BIT) AS showNDA2Modal
					,CAST('false' AS BIT) AS isCustomNDA
					,CAST('false' AS BIT) AS showNDA2ModalWarning
					,CAST('false' AS BIT) AS isFileDownloadable
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			)

	END

	-- for starter users hide NDA 1 Modal / NDA2 Modal  and disable file download
	IF @AccountType = 313
	BEGIN
		
		SET @RfqAccessInfo =
			(
				SELECT 
					CAST('false' AS BIT)  AS showNDA1Modal 
					,CAST('false' AS BIT) AS showNDA2Modal
					,CAST('false' AS BIT) AS isCustomNDA
					,CAST('false' AS BIT) AS showNDA2ModalWarning
					,CAST('false' AS BIT) AS isFileDownloadable
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			)

	END
	
	-- for growth users hide NDA 1 Modal / NDA2 Modal  and disable file download
	IF @AccountType = 84
	BEGIN

		;WITH cte AS 
		(
			SELECT   MAX(b.subscription_start)  subscription_start 
			, MAX(b.subscription_end) subscription_end
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			WHERE a.gateway_id = 310 
			AND a.company_id = @CompanyId
		)  
		SELECT  TOP 1     
			@SubscriptionStatus =   b.status 
			,@RunningSubscriptionId = b.id 
		FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
		JOIN cte on cte.subscription_start = b.subscription_start and cte.subscription_end = b.subscription_end
		WHERE a.gateway_id = 310 
		AND a.company_id = @CompanyId
		ORDER BY b.ID DESC

		IF @SubscriptionStatus = 'active'
		BEGIN
		    ---- getting RFQ count as per company level based on current subscription start and end date range
			SET @UnlockedRfqsCount =
			(
				SELECT COUNT(DISTINCT c.rfq_id)
				FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
					a.id = b.customer_id 
					AND a.company_id = @CompanyId
				JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
					AND c.IsDeleted = 0
				WHERE 
					b.id = @RunningSubscriptionId
					AND c.UnlockDate  >= b.subscription_start
					AND c.UnlockDate <= b.subscription_end
			)

		END
		ELSE
		BEGIN
			---- getting RFQ count as per company level based on current subscription start and end date range
			SET @UnlockedRfqsCount =
				(
					SELECT COUNT(DISTINCT c.rfq_id)
					FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
					JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
					a.id = b.customer_id 
					AND a.company_id = @CompanyId
					JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
						AND c.IsDeleted = 0
					WHERE 
						b.id = @RunningSubscriptionId
						AND c.UnlockDate  >= b.subscription_start
						AND CAST(c.UnlockDate AS DATE) <=  CAST(DATEADD(dd,30, b.subscription_end) AS DATE)
			   )
		END

		
		SET @MatchedPartCount = 
		(
			SELECT 
				COUNT(c.part_category_id) MatchedPartCount
			FROM mp_rfq					(NOLOCK) a
			LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
			LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 			WHERE  
				a.rfq_id = @RfqId
			GROUP BY a.rfq_id
		)

		SET @ActionForGrowthPackage = 
		(
			CASE	
				WHEN @IsRfqUnlocked IS NOT NULL  THEN 'No Action'
				WHEN @UnlockedRfqsCount = 3 OR @NDALevel = 2 THEN 'Upgrade to Quote'
				WHEN @UnlockedRfqsCount < 3 AND @MatchedPartCount = 0  THEN 'Upgrade to Quote'
				ELSE 'Unlock Rfq Button'
			END
		
		)

		IF @NDALevel = 1 
		BEGIN

			SET @RfqAccessInfo =
			(
				SELECT 
					CASE 
						WHEN @IsCustomNDA > 0 THEN CAST('false' AS BIT)
						WHEN @ActionForGrowthPackage IN  ('Upgrade to Quote' , 'Unlock Rfq Button' ) THEN CAST('false' AS BIT)
						WHEN @ActionForGrowthPackage IN  ('No Action') AND @IsNDAAcceptedBySupplier IS  NULL THEN CAST('true' AS BIT)
						WHEN @ActionForGrowthPackage IN  ('No Action') AND @IsNDAAcceptedBySupplier IS NOT NULL THEN CAST('false' AS BIT)
					END AS showNDA1Modal
					,CAST('false' AS BIT) AS showNDA2Modal
					,CASE WHEN @IsCustomNDA > 0 AND @IsNDAAcceptedBySupplier IS  NULL AND @ActionForGrowthPackage IN  ('No Action') THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END isCustomNDA
					,CAST('false' AS BIT) AS showNDA2ModalWarning
					,CASE 
						WHEN @ActionForGrowthPackage IN  ('Upgrade to Quote' , 'Unlock Rfq Button' ) THEN CAST('false' AS BIT)
						WHEN @ActionForGrowthPackage IN  ('No Action') AND @IsNDAAcceptedBySupplier IS NULL THEN CAST('false' AS BIT)
						WHEN @ActionForGrowthPackage IN  ('No Action') AND @IsNDAAcceptedBySupplier IS NOT NULL THEN CAST('true' AS BIT)
					END AS isFileDownloadable
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			)
		END

		IF @NDALevel = 2 
		BEGIN

			SET @RfqAccessInfo =
			(
				SELECT 
					CAST('false' AS BIT) AS showNDA1Modal 
					,CAST('false' AS BIT) AS showNDA2Modal
					,CAST('false' AS BIT) AS isCustomNDA
					,CAST('false' AS BIT) AS showNDA2ModalWarning
					,CAST('false' AS BIT) AS isFileDownloadable
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			)
		END

	END

	-- for growth users hide NDA 1 Modal / NDA2 Modal  and disable file download
	IF @AccountType IN (85,86)
	BEGIN

		SET @MatchedPartCount = 
		(
			SELECT 
				COUNT(c.part_category_id) MatchedPartCount
			FROM mp_rfq					(NOLOCK) a
			LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
			LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 			WHERE  
				a.rfq_id = @RfqId
			GROUP BY a.rfq_id
		)

		IF @NDALevel = 1 
		BEGIN

			SET @RfqAccessInfo =
			(
				SELECT 
					CASE 
						WHEN @IsCustomNDA > 0 THEN CAST('false' AS BIT)
						WHEN @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 AND @IsNDAAcceptedBySupplier IS  NULL  THEN CAST('true' AS BIT)
						ELSE CAST('false' AS BIT)
					END AS showNDA1Modal
					,CAST('false' AS BIT) AS showNDA2Modal
					,CASE WHEN @IsCustomNDA > 0 AND @IsNDAAcceptedBySupplier IS  NULL AND @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END isCustomNDA
					,CAST('false' AS BIT) AS showNDA2ModalWarning
					,CASE 
						WHEN @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 AND @IsNDAAcceptedBySupplier IS  NOT NULL  THEN CAST('true' AS BIT)
						ELSE CAST('false' AS BIT)						
					END AS isFileDownloadable
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			)
		END

		IF @NDALevel = 2 
		BEGIN

			SET @RfqAccessInfo =
			(
				SELECT 
					CAST('false' AS BIT) AS showNDA1Modal
					,CASE 
						WHEN @IsCustomNDA > 0 THEN CAST('false' AS BIT)
						WHEN @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 AND @IsNDAAcceptedBySupplier IS  NULL  THEN CAST('true' AS BIT)
						ELSE CAST('false' AS BIT)
					END AS showNDA2Modal
					,CASE WHEN @IsCustomNDA > 0 AND @IsNDAAcceptedBySupplier IS  NULL AND @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END isCustomNDA
					,CASE 
						WHEN @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 AND @IsNDAAcceptedBySupplier IS  NOT NULL  AND @IsNDAApprovedByBuyer IS NULL THEN CAST('true' AS BIT)
						ELSE CAST('false' AS BIT)						
					 END AS showNDA2ModalWarning
					,CASE 
						WHEN @IsSubscriptionSupplier = 1  AND @MatchedPartCount > 0 AND @IsNDAAcceptedBySupplier IS  NOT NULL  AND @IsNDAApprovedByBuyer = 1 THEN CAST('true' AS BIT)
						ELSE CAST('false' AS BIT)						
					END AS isFileDownloadable
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			)
		END

	END


	SELECT 
		@RfqAccessInfo	AS RfqAccessInfo 
		, @RfqId		AS RfqId
		, @SupplierId	AS SupplierId
		, @CompanyId	AS CompanyId 
		, @AccountType	AS AccountType
		, @NDALevel		AS NDALevel
		, @IsCustomNDA	AS IsCustomNDA
		, @IsRfqUnlocked AS IsRfqUnlocked
		, @ActionForGrowthPackage AS ActionForGrowthPackage
		, @UnlockedRfqsCount AS UnlockedRfqsCount
		, @IsNDAAcceptedBySupplier AS IsNDAAcceptedBySupplier
		, @IsNDAApprovedByBuyer AS IsNDAApprovedByBuyer
		, @IsSubscriptionSupplier AS IsSubscriptionSupplier
		, @MatchedPartCount AS MatchedPartCount



END
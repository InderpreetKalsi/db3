
/*

select * from mp_contacts where contact_id  = 1350506

EXEC proc_get_GrowthPackageRfqAccessInfo
@RfqId = 1159292
,@CompanyId = 1770384

EXEC proc_get_GrowthPackageRfqAccessInfo
@RfqId = 1194738
,@CompanyId = 1800874

*/
--M2-4653 M - Unlock buttons for the RFQ drawer and RFQ Details page - DB 
CREATE PROCEDURE [dbo].[proc_get_GrowthPackageRfqAccessInfo]
(
	@RfqId	INT
	,@CompanyId INT
)
AS
BEGIN

	 ---- DECLARE @RfqId	INT =1159287 ,@CompanyId INT = 1770384

	--M2-4653 M - Unlock buttons for the RFQ drawer and RFQ Details page - DB 
	SET NOCOUNT ON
		
	DECLARE @IsSubscriptionSupplier		BIT = 0
	DECLARE @IsAllowQuoting				BIT = 0
	DECLARE @IsRfqUnlocked				BIT = 0
	DECLARE @UnlockedRfqsCount			INT = 0
	DECLARE @RfqNDALevel				INT = 0
	DECLARE @IsRfqQuoted				INT = 0
	DECLARE @PaidStatus					INT = 0
	DECLARE @IsWithOrderManagement		BIT = 0 --M2-4793
	/* M2-4686 */
	DECLARE @SubscriptionStatus VARCHAR(25), @RunningSubscriptionId INT

	 ---- below code commented with M2-5221
	 ---- Getting status and latest running id against company id
	 --SELECT  TOP 1  @SubscriptionStatus =   b.status , @RunningSubscriptionId = b.id 
		--FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		--JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
		--WHERE a.gateway_id = 310 
		--AND a.company_id = @CompanyId
		--ORDER BY b.ID DESC

	 ------ Updated code with M2-5221
		;WITH cte AS 
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

	
    /* END : M2-4686 */
	
	SET @IsSubscriptionSupplier =(SELECT COUNT(1) FROM mp_gateway_subscription_company_processes (NOLOCK)  WHERE  company_id =  @CompanyId AND is_active = 1)
	SET @IsRfqUnlocked =(SELECT COUNT(1) FROM mpGrowthPackageUnlockRFQsInfo (NOLOCK) WHERE CompanyId =  @CompanyId   AND Rfq_Id = @RfqId 
	/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
	AND ISNULL(IsDeleted,0) = 0
	)
	/* M2-4793 */
	SET @IsWithOrderManagement =(SELECT ISNULL(WithOrderManagement,0) FROM mp_rfq (NOLOCK) WHERE Rfq_Id= @RfqId  )
	/**/

	SET @IsRfqQuoted =
	(
		SELECT COUNT(1)
		FROM mp_rfq_quote_SupplierQuote	mrqsq	(NOLOCK) 
		join mp_rfq b							(NOLOCK) on mrqsq.rfq_id = b.rfq_id 
			AND rfq_status_id in  (3 , 5, 6 ,16, 17 ,18 ,20) 
			--AND  is_rfq_resubmitted = 0
			AND  mrqsq.is_quote_submitted = 1
			AND b.rfq_id = @RfqId
			AND mrqsq.contact_id IN 
				(
					SELECT contact_id FROM mp_contacts (NOLOCK) 
					WHERE company_id  = @CompanyId AND is_buyer = 0
				)
	)

	SELECT 
		@RfqNDALevel		= a.pref_NDA_Type
		,@IsAllowQuoting	= COUNT(c.part_category_id) 
	FROM mp_rfq					(NOLOCK) a
	LEFT JOIN mp_rfq_parts		(NOLOCK) b 
		ON a.rfq_id = b.rfq_id AND b.status_id  = 2
	LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c 
		ON	b.part_category_id = c.part_category_id 
			AND c.company_id = @CompanyId  
			AND c.is_active = 1
 	WHERE a.rfq_id  =  @RfqId 
	GROUP BY a.pref_NDA_Type

	
	
	IF @SubscriptionStatus = 'active'
	BEGIN
		
		

		SET @UnlockedRfqsCount =
		(
			SELECT COUNT(DISTINCT c.rfq_id)
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
				a.id = b.customer_id 
				AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
				AND a.company_id = @CompanyId
			JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
			/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
						AND ISNULL(c.IsDeleted ,0) = 0
			WHERE 
				b.id = @RunningSubscriptionId
				AND c.UnlockDate  >= b.subscription_start
				AND c.UnlockDate <= b.subscription_end
		)
	END
	ELSE
	BEGIN
		SET @UnlockedRfqsCount =
		(
			SELECT COUNT(DISTINCT c.rfq_id)
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
				a.id = b.customer_id 
				AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
				AND a.company_id = @CompanyId
			JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
			/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
						AND ISNULL(c.IsDeleted ,0) = 0
			WHERE 
				b.id = @RunningSubscriptionId
				AND c.UnlockDate  >= b.subscription_start
					AND CAST(c.UnlockDate AS DATE) <=  CAST(DATEADD(dd,30, b.subscription_end) AS DATE)

		)		
	END
		
	--SELECT @IsRfqQuoted , @IsRfqUnlocked , @UnlockedRfqsCount  , @RfqNDALevel  , @IsAllowQuoting
	
	SELECT 
		(
			
			CASE	
					WHEN @IsRfqQuoted > 0 THEN 'No Action'
					WHEN @IsRfqUnlocked > 0  THEN 'No Action'
					WHEN @UnlockedRfqsCount = 3 OR @RfqNDALevel = 2 THEN 'Upgrade to Quote'
					WHEN @UnlockedRfqsCount < 3 AND @IsAllowQuoting = 0  THEN 'Upgrade to Quote'
					ELSE 'Unlock Rfq Button'
			END

		 ) AS ActionForGrowthPackage
		 /* M2-4793 */
		 , @IsWithOrderManagement AS WithOrderManagement
		 /**/
END

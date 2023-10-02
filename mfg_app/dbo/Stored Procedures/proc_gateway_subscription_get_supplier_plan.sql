
/*


EXEC [proc_gateway_subscription_get_supplier_plan] @supplier_id = 1368767
EXEC [proc_gateway_subscription_get_supplier_payment_method] @supplier_id = 1368767
EXEC [proc_gateway_subscription_get_invoices] @supplier_id = 1368767
SELECT * FROM mp_registered_supplier (NOLOCK) WHERE company_id = 1771857

*/
CREATE PROCEDURE [dbo].[proc_gateway_subscription_get_supplier_plan]
(
	@supplier_id		INT
)
AS
BEGIN
 
	/*
		CREATED	:	MAR 18, 2020	
		DESC	:	M2-2713 M - Billing History and Contract page - DB
	*/
	SET NOCOUNT ON
 
	DROP TABLE IF EXISTS #ListofContacts

	DECLARE @CompanyId INT = (SELECT company_id FROM mp_contacts (NOLOCK) WHERE contact_id = @supplier_id)

	DECLARE @ManufacturerAccountType INT = (SELECT account_type FROM mp_registered_supplier (NOLOCK) WHERE company_id = @CompanyId)
	
	SELECT contact_id 
	INTO #ListofContacts
	FROM mp_contacts (NOLOCK) WHERE company_id IN
	(
		SELECT company_id FROM mp_contacts (NOLOCK) WHERE contact_id = @supplier_id
	)
	
	SELECT 
			a.subscription_customer_id AS SubscriptionCustomerId
		--,b.subscription_id  AS SubscriptionId
		,(CASE WHEN b.status in ('active' , 'live', 'trialing') THEN b.subscription_id  ELSE '' END) AS  SubscriptionId
		,(CASE WHEN b.status in ('active' , 'live', 'trialing') THEN d.name ELSE 'Basic' END) AS ActiveSubscriptionPlan
		,(
			CASE 
				WHEN b.status in ('active' , 'live', 'trialing') THEN 
					CASE 
						WHEN  b.SubscriptionInterval = 'month' THEN ' Monthly Rate: ' 
						ELSE ''
					END 
				ELSE '' 
			END
			) AS SubscriptionInterval
		,(
			CASE 
				WHEN b.status in ('active' , 'live', 'trialing')  THEN '$'+CONVERT(VARCHAR(250),b.TotalAmout/100)
				ELSE '' 
			END
			) AS SubscriptionPlanPrice
		,(CASE WHEN b.status in ('active' , 'live', 'trialing')  THEN FORMAT(b.next_billing_at,'MM/dd/yyyy ') ELSE '' END) AS NextBillingDate
		, a.gateway_id AS GatewayType
		, CASE WHEN b.status =    'trialing' THEN 1 ELSE 0 END         AS IsTrial
		, (CASE WHEN b.status ='trialing'  THEN CASE WHEN GETUTCDATE() <=  b.subscription_end THEN 1 ELSE DATEDIFF(dd,GETUTCDATE(),(b.subscription_end)) END ELSE '' END) AS [NumberOfTrialDaysLeft]
		, (CASE WHEN b.status in ('active' , 'live', 'trialing')  THEN FORMAT(b.subscription_end,'MM/dd/yyyy ') ELSE '' END) AS NextRenewalDate

	FROM  [dbo].[mp_gateway_subscription_customers] a (NOLOCK)
	JOIN
	(
		SELECT a.customer_id, a.plan_id ,a.subscription_end , a.subscription_id ,a.next_billing_at ,a.status , a.addon , a.addon_quantity , a.SubscriptionInterval ,a.TotalAmout
		FROM  [dbo].[mp_gateway_subscriptions] (NOLOCK) a
		JOIN
		(
			SELECT a.id FROM
			(
				SELECT customer_id , id , status , subscription_id 
				FROM  [dbo].[mp_gateway_subscriptions] (NOLOCK)
				WHERE status IN ('trialing','active')				
			) a
			LEFT JOIN 
			(
				SELECT customer_id , id  , status, subscription_id
				FROM  [dbo].[mp_gateway_subscriptions] (NOLOCK)
				WHERE status NOT IN ('trialing','active')
				
			) b ON a.customer_id = b.customer_id AND a.subscription_id = b.subscription_id
			WHERE b.customer_id IS NULL
		) b on a.id = b.id
	) b on a.id =  b.customer_id
	JOIN mp_gateway_subscription_products			(NOLOCK) d ON d.id = b.plan_id
	LEFT JOIN mp_gateway_subscription_pricing_plan_add_ons		(NOLOCK) e ON b.addon = e.addon_code
	WHERE 
		a.supplier_id  IN (SELECT contact_id FROM #ListofContacts)
		AND a.is_active = 1 
		AND @ManufacturerAccountType IN (84,85,86,313)

	DROP TABLE IF EXISTS #ListofContacts

END

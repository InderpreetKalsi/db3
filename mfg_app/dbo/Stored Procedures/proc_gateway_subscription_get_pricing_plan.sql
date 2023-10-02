
/*
EXEC [proc_gateway_subscription_get_pricing_plan] @upgrade_id		= 1001 , @interval = 'Quarterly'
EXEC [proc_gateway_subscription_get_pricing_plan] @upgrade_id		= 1002 , @interval = 'Quarterly'
EXEC [proc_gateway_subscription_get_pricing_plan] @upgrade_id		= 1003 , @interval = 'Quarterly'

EXEC [proc_gateway_subscription_get_pricing_plan] @upgrade_id		= 1001 , @interval = 'Yearly'
EXEC [proc_gateway_subscription_get_pricing_plan] @upgrade_id		= 1002 , @interval = 'Yearly'
EXEC [proc_gateway_subscription_get_pricing_plan] @upgrade_id		= 1003 , @interval = 'Yearly'
*/
CREATE  PROCEDURE [dbo].[proc_gateway_subscription_get_pricing_plan]
(
	@upgrade_id		INT
	,@interval		VARCHAR(100) = 'Quarterly'
)
AS
BEGIN

	/*
		CREATED	:	MAR 13, 2020	
		DESC	:	M2-2701 M - Directory Subscription selection - DB
	*/

	SET NOCOUNT ON


	SELECT DISTINCT
		a.id						AS UpgradeTitleId 
		,a.upgrade_title			AS UpgradeTitle 
		,c.id						AS ProductId
		,c.subscription_product_id	AS SubscriptionProductId
		,c.name						AS Product
		,d.id						AS PricingPlanId
		,d.plan_code				AS SubscriptionPricingPlanId
		,d.price					AS PlanPrice
		,d.billing_interval			AS BillingInterval
		,CASE WHEN c.is_enable = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END AS IsEnable
		,e.addon_code				AS AddOn
		,CASE 
			WHEN c.name = 'Gold' AND d.billing_interval = 'Quarterly' THEN CONVERT(INT,e.addon_price)	*3 
			ELSE CONVERT(INT,e.addon_price) 
		 END				AS AddOnPrice
	FROM mp_gateway_subscription_account_upgrades						(NOLOCK) a
	JOIN mp_gateway_subscription_account_upgrade_product_mappings		(NOLOCK) b ON a.id = b.upgrade_id
	JOIN mp_gateway_subscription_products								(NOLOCK) c ON b.product_id = c.id AND c.is_active =1
	JOIN mp_gateway_subscription_pricing_plans							(NOLOCK) d ON c.id = d.product_id AND d.is_active =1
	LEFT JOIN mp_gateway_subscription_pricing_plan_add_ons				(NOLOCK) e ON  d.id = e.pricing_plan_id
	WHERE 
		a.id = @upgrade_id
		AND d.billing_interval = @interval
	ORDER BY UpgradeTitleId, PricingPlanId DESC


END

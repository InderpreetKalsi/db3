
/*

EXEC [proc_gateway_subscription_get_specific_pricing_plan] @pricing_plan_id = 1005
EXEC [proc_gateway_subscription_get_specific_pricing_plan] @pricing_plan_id = 1006
EXEC [proc_gateway_subscription_get_specific_pricing_plan_features] @pricing_plan_id	= 1005

*/
CREATE  PROCEDURE [dbo].[proc_gateway_subscription_get_specific_pricing_plan]
(
	@pricing_plan_id		INT
)
AS
BEGIN

	/*
		CREATED	:	Apr 15, 2020	
	*/

	SET NOCOUNT ON


	SELECT DISTINCT
		c.id						AS ProductId
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
		 END 			AS AddOnPrice
	FROM mp_gateway_subscription_products			(NOLOCK) c
	JOIN mp_gateway_subscription_pricing_plans		(NOLOCK) d ON c.id = d.product_id AND d.is_active =1
	LEFT JOIN mp_gateway_subscription_pricing_plan_add_ons (NOLOCK) e ON  d.id = e.pricing_plan_id
	WHERE 
		d.id = @pricing_plan_id
		
END

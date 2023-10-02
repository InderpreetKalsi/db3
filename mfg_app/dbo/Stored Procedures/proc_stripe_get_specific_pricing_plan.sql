
/*

EXEC [proc_stripe_get_specific_pricing_plan] @pricing_plan_id = 1008
EXEC [proc_stripe_get_specific_pricing_plan_features] @pricing_plan_id	= 1008 

*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_specific_pricing_plan]
(
	@pricing_plan_id		INT
)
AS
BEGIN

	/*
		CREATED	:	MAR 13, 2020	
		DESC	:	M2-2701 M - Directory Subscription selection - DB
	*/

	SET NOCOUNT ON


	SELECT DISTINCT
		c.id						AS ProductId
		,c.stripe_product_id		AS StripeProductId
		,c.name						AS Product
		,d.id						AS PricingPlanId
		,d.stripe_pricing_plan_id	AS StripePricingPlanId
		,d.price					AS PlanPrice
		,d.billing_interval			AS BillingInterval
		,CASE WHEN c.is_enable = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END AS IsEnable
	FROM mp_stripe_products			(NOLOCK) c
	JOIN mp_stripe_pricing_plans	(NOLOCK) d ON c.id = d.product_id AND d.is_active =1
	WHERE 
		d.id = @pricing_plan_id
		
END

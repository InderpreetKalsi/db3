
/*
EXEC proc_stripe_get_pricing_plan @upgrade_id		= 1001 , @interval = 'Quarterly'
EXEC proc_stripe_get_pricing_plan @upgrade_id		= 1002 , @interval = 'Quarterly'
EXEC proc_stripe_get_pricing_plan @upgrade_id		= 1003 , @interval = 'Quarterly'

EXEC proc_stripe_get_pricing_plan @upgrade_id		= 1001 , @interval = 'Yearly'
EXEC proc_stripe_get_pricing_plan @upgrade_id		= 1002 , @interval = 'Yearly'
EXEC proc_stripe_get_pricing_plan @upgrade_id		= 1003 , @interval = 'Yearly'
*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_pricing_plan]
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
		,c.stripe_product_id		AS StripeProductId
		,c.name						AS Product
		,d.id						AS PricingPlanId
		,d.stripe_pricing_plan_id	AS StripePricingPlanId
		,d.price					AS PlanPrice
		,d.billing_interval			AS BillingInterval
		,CASE WHEN c.is_enable = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END AS IsEnable
		
	FROM mp_stripe_account_upgrades						(NOLOCK) a
	JOIN mp_stripe_account_upgrade_product_mappings		(NOLOCK) b ON a.id = b.upgrade_id
	JOIN mp_stripe_products								(NOLOCK) c ON b.product_id = c.id AND c.is_active =1
	JOIN mp_stripe_pricing_plans						(NOLOCK) d ON c.id = d.product_id AND d.is_active =1
	WHERE 
		a.id = @upgrade_id
		AND d.billing_interval = @interval
	ORDER BY UpgradeTitleId, PricingPlanId DESC


END

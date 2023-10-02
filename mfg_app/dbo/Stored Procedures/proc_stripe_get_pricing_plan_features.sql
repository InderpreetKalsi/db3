
/*
EXEC [proc_stripe_get_pricing_plan_features] @upgrade_id	= 1001 , @interval = 'Quarterly'
EXEC [proc_stripe_get_pricing_plan_features] @upgrade_id	= 1002 , @interval = 'Quarterly' 
EXEC [proc_stripe_get_pricing_plan_features] @upgrade_id	= 1003 , @interval = 'Quarterly' 

EXEC [proc_stripe_get_pricing_plan_features] @upgrade_id	= 1001 , @interval = 'Yearly' 
EXEC [proc_stripe_get_pricing_plan_features] @upgrade_id	= 1002 , @interval = 'Yearly'
EXEC [proc_stripe_get_pricing_plan_features] @upgrade_id	= 1003 , @interval = 'Yearly' 
*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_pricing_plan_features]
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

	SELECT 
		a.product_id	AS StripeProductId
		,
		CASE 
			WHEN a.feature = 'Buyer Leads' THEN
				CASE	
					WHEN @interval	= 'Quarterly' THEN ISNULL(CONVERT(VARCHAR(100),CONVERT(INT,a.value)*3)+' ','') +a.feature	
					WHEN @interval	= 'Yearly' THEN ISNULL(CONVERT(VARCHAR(100),CONVERT(INT,a.value)*12)+' ','') +a.feature	
				END
			ELSE
				ISNULL(a.value+' ','') +a.feature		
		END AS StripeProductFeature
		,ISNULL(b.value+' ','') + b.feature		AS StripeProductSubFeature
		,CASE WHEN a.is_include = 1 THEN CAST('true' AS BIT) ELSE  CAST('false' AS BIT)  END AS IsFeatureEnable 
		,CASE WHEN b.is_include = 1 THEN CAST('true' AS BIT) ELSE  CAST('false' AS BIT)  END AS IsSubFeatureEnable
	FROM mp_stripe_product_features					(NOLOCK) a
	LEFT JOIN mp_stripe_product_features			(NOLOCK) b ON a.id = b.parent_id 
	JOIN mp_stripe_account_upgrade_product_mappings	(NOLOCK) c ON c.product_id = a.product_id
	JOIN mp_stripe_account_upgrades					(NOLOCK) d ON d.id = c.upgrade_id
	JOIN mp_stripe_products							(NOLOCK) e ON c.product_id = e.id AND e.is_active =1
	JOIN mp_stripe_pricing_plans					(NOLOCK) f ON e.id = f.product_id AND f.is_active =1
	WHERE 
	a.is_active =  1  
	AND a.parent_id= 0
	AND	d.id = @upgrade_id
	AND f.billing_interval = @interval
	ORDER BY StripeProductId DESC, a.id , b.id	


END

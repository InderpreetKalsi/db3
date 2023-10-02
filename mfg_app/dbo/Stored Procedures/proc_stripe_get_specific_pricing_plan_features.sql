
/*
EXEC [proc_stripe_get_specific_pricing_plan] @pricing_plan_id = 1008
EXEC [proc_stripe_get_specific_pricing_plan_features] @pricing_plan_id	= 1008 
*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_specific_pricing_plan_features]
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

	SELECT 
		f.product_id	AS StripeProductId
		,CASE 
			WHEN a.feature = 'Buyer Leads' THEN
				CASE	
					WHEN billing_interval	= 'Quarterly' THEN ISNULL(CONVERT(VARCHAR(100),CONVERT(INT,a.value)*3)+' ','') +a.feature	
					WHEN billing_interval	= 'Yearly' THEN ISNULL(CONVERT(VARCHAR(100),CONVERT(INT,a.value)*12)+' ','') +a.feature	
				END
			ELSE
				ISNULL(a.value+' ','') +a.feature		
		 END 			AS StripeProductFeature
		,ISNULL(b.value+' ','') + b.feature		AS StripeProductSubFeature
		,CASE WHEN a.is_include = 1 THEN CAST('true' AS BIT) ELSE  CAST('false' AS BIT)  END AS IsFeatureEnable 
		,CASE WHEN b.is_include = 1 THEN CAST('true' AS BIT) ELSE  CAST('false' AS BIT)  END AS IsSubFeatureEnable
	FROM 
	mp_stripe_pricing_plans					(NOLOCK) f
	JOIN mp_stripe_products					(NOLOCK) e ON e.id = f.product_id AND f.is_active =1
	LEFT JOIN mp_stripe_product_features		(NOLOCK) a ON a.product_id = e.id AND e.is_active =1
	LEFT JOIN mp_stripe_product_features		(NOLOCK) b ON a.id = b.parent_id 
	WHERE 
		f.id =  @pricing_plan_id 
		AND a.is_active =  1  
		AND a.parent_id= 0 
	ORDER BY StripeProductId DESC



END

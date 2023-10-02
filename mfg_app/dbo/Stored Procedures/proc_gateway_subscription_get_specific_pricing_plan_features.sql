
/*
EXEC [proc_gateway_subscription_get_specific_pricing_plan] @pricing_plan_id = 1005
EXEC [proc_gateway_subscription_get_specific_pricing_plan_features] @pricing_plan_id	= 1005
*/
CREATE  PROCEDURE [dbo].[proc_gateway_subscription_get_specific_pricing_plan_features]
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
		f.product_id	AS SubscriptionProductId
		,CASE 
			WHEN a.feature = 'Buyer Leads' THEN
				CASE	
					WHEN billing_interval	= 'Quarterly' THEN ISNULL(CONVERT(VARCHAR(100),CONVERT(INT,a.value))+' ','') +a.feature	
					WHEN billing_interval	= 'Yearly' THEN ISNULL(CONVERT(VARCHAR(100),CONVERT(INT,a.value)*4)+' ','') +a.feature	
				END
			ELSE
				ISNULL(a.value+' ','') +a.feature		
		 END 			AS SubscriptionProductFeature
		,ISNULL(b.value+' ','') + b.feature		AS SubscriptionProductSubFeature
		,CASE WHEN a.is_include = 1 THEN CAST('true' AS BIT) ELSE  CAST('false' AS BIT)  END AS IsFeatureEnable 
		,CASE WHEN b.is_include = 1 THEN CAST('true' AS BIT) ELSE  CAST('false' AS BIT)  END AS IsSubFeatureEnable
		,CASE WHEN e.name = 'Gold' THEN 
				CASE WHEN a.feature = 'RFQ Categories' THEN CONVERT(INT,a.value) ELSE NULL END  
			 ELSE NULL END AS DefaultCategoryCount
	FROM 
	mp_gateway_subscription_pricing_plans					(NOLOCK) f
	JOIN mp_gateway_subscription_products					(NOLOCK) e ON e.id = f.product_id AND f.is_active =1
	LEFT JOIN mp_gateway_subscription_product_features		(NOLOCK) a ON a.product_id = e.id AND e.is_active =1
	LEFT JOIN mp_gateway_subscription_product_features		(NOLOCK) b ON a.id = b.parent_id 
	WHERE 
		f.id =  @pricing_plan_id 
		AND a.is_active =  1  
		AND a.parent_id= 0 
	ORDER BY SubscriptionProductId DESC


END

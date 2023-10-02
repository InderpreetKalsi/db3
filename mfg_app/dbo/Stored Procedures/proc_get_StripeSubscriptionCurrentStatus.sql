

/*
M2-5219 MixPanel - Complete new supplier events from API side

exec [dbo].[proc_get_StripeSubscriptionCurrentStatus]  'sub_1NkT3SGWEpBLxDeP8Z7bbJ7N' 

*/
CREATE   PROCEDURE [dbo].[proc_get_StripeSubscriptionCurrentStatus] 
(
	@StripeSubscriptionId VARCHAR(100)
)
AS
BEGIN

	;with cte as 
		(
			SELECT   max(b.subscription_start)  subscription_start ,max(b.subscription_end) subscription_end
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			WHERE b.subscription_id = @StripeSubscriptionId
		)  
		SELECT  TOP 1    
		CASE WHEN  c.account_type = 84 THEN 'Growth' 
			   WHEN  c.account_type = 313 THEN 'Starter'
			   ELSE NULL END AS [AccountType]
		, b.status AS [Status]
		FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
		JOIN cte on cte.subscription_start = b.subscription_start and cte.subscription_end = b.subscription_end
		JOIN mp_registered_supplier (nolock)c on c.company_id = a.company_id
		WHERE a.gateway_id = 310 
		AND  b.subscription_id = @StripeSubscriptionId
		ORDER BY b.ID DESC


END

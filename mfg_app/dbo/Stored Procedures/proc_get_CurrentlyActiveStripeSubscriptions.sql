 
/*
exec proc_get_CurrentlyActiveStripeSubscriptions  'cus_OLSuNf4Js5Smdi' 
*/
CREATE PROCEDURE proc_get_CurrentlyActiveStripeSubscriptions 
(
	@SubscriptionCustomerId VARCHAR(100)
)
AS
BEGIN
	--DECLARE @SubscriptionCustomerId VARCHAR(100) =  'cus_OLSuNf4Js5Smdi' 
 
	DROP TABLE IF EXISTS  #tmpActivetrialingSubscription
	DROP TABLE IF EXISTS  #tmpSubscriptionCnt
 

	---- Getting active and trialing status records
	SELECT   
		b.id 
		,b.subscription_id
		,b.status
		,plan_id
	-- ,ROW_NUMBER() OVER (PARTITION BY b.subscription_id ,plan_id ORDER BY b.id ) rn
	INTO #tmpActivetrialingSubscription
	FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
	JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
	WHERE a.gateway_id = 310 
	AND a.subscription_customer_id  =  @SubscriptionCustomerId
	AND b.status IN ('active','trialing')
 
		 
	---- Getting count as per subscription_id
	SELECT   
	b.subscription_id
	,COUNT (1) AS rowcnt	
	INTO #tmpSubscriptionCnt
	FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
	JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
	WHERE a.gateway_id = 310 
	AND a.subscription_customer_id  = @SubscriptionCustomerId
	GROUP BY  b.subscription_id

	---Delete those records from table where rowcnt > 1
	DELETE FROM #tmpActivetrialingSubscription WHERE subscription_id IN (SELECT subscription_id FROM #tmpSubscriptionCnt WHERE rowcnt >1 )

	---Final result set  
	SELECT subscription_id AS SubscriptionId ,[status] FROM #tmpActivetrialingSubscription
 
END
